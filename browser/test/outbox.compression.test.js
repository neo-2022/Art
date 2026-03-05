import test from "node:test";
import assert from "node:assert/strict";
import zlib from "node:zlib";
import { promisify } from "node:util";

import { InMemoryOutboxStore, Level0Outbox } from "../src/outbox.js";

const gzip = promisify(zlib.gzip);
const gunzip = promisify(zlib.gunzip);

const nodeGzipCodec = {
  gzip: async (bytes) => new Uint8Array(await gzip(Buffer.from(bytes))),
  gunzip: async (bytes) => new Uint8Array(await gunzip(Buffer.from(bytes))),
};

test("unit: outbox gzip compress/decompress >1024 bytes", async () => {
  const store = new InMemoryOutboxStore();
  const ingested = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async (payload) => {
      ingested.push(payload);
    },
    codec: nodeGzipCodec,
    now: () => 1000,
  });

  const bigPayload = "A".repeat(3000);
  const event = {
    kind: "raw.event",
    payload: { bigPayload },
    ts_ms: 1234,
  };

  const record = await outbox.enqueue(event);
  assert.equal(record.content_encoding, "gzip");
  assert.equal(record.original_size_bytes > 1024, true);
  assert.equal(record.stored_size_bytes < record.original_size_bytes, true);

  await outbox.flushAll();
  assert.equal(ingested.length, 1);
  assert.deepEqual(ingested[0].event, event);
  assert.equal(ingested[0].content_encoding, "gzip");
  assert.equal(ingested[0].original_size_bytes, record.original_size_bytes);
  assert.equal(ingested[0].stored_size_bytes, record.stored_size_bytes);
});

test("integration: payload >1024 flush delivers valid RawEvent", async () => {
  const store = new InMemoryOutboxStore();
  const ingested = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async (payload) => {
      ingested.push(payload);
    },
    codec: nodeGzipCodec,
    now: () => 2000,
  });

  const event = {
    kind: "raw.event",
    payload: {
      source: "browser.level0",
      data: "X".repeat(2048),
    },
    ts_ms: 2222,
  };

  await outbox.enqueue(event);
  await outbox.flushAll();

  assert.equal(ingested.length, 1);
  assert.deepEqual(ingested[0].event, event);
  assert.ok(typeof ingested[0].dedup_key === "string" && ingested[0].dedup_key.length > 0);
});

test("integration: bad gzip generates observability_gap.outbox_decompress_failed", async () => {
  const store = new InMemoryOutboxStore();
  const gapEvents = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async () => {},
    codec: {
      gzip: nodeGzipCodec.gzip,
      gunzip: async () => {
        throw new Error("corrupted gzip payload");
      },
    },
    emitGapFn: async (event) => {
      gapEvents.push(event);
    },
    now: () => 3000,
    ingestEndpoint: "https://art.local/api/v1/ingest",
    browserOrigin: "https://ui.local",
  });

  await outbox.enqueue({
    kind: "raw.event",
    payload: { data: "Y".repeat(2048) },
    ts_ms: 3333,
  });

  await assert.rejects(outbox.flushAll(), /corrupted gzip payload/);
  assert.equal(gapEvents.length, 1);
  assert.equal(gapEvents[0].kind, "observability_gap.outbox_decompress_failed");
  assert.equal(gapEvents[0].where, "browser.outbox.flush");
  assert.ok(typeof gapEvents[0].trace_id === "string" && gapEvents[0].trace_id.length > 0);
  assert.equal(gapEvents[0].evidence.endpoint, "https://art.local/api/v1/ingest");
  assert.equal(gapEvents[0].evidence.browser_origin, "https://ui.local");
  assert.ok(typeof gapEvents[0].evidence.dedup_key === "string");
});
