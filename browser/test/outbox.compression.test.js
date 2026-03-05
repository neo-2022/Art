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

function workerFactoryOk() {
  return {
    async execute(_operationName, runOnMainThread) {
      return runOnMainThread();
    },
  };
}

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
    workerFactory: workerFactoryOk,
  });

  const event = {
    kind: "raw.event",
    payload: { bigPayload: "A".repeat(3000) },
    ts_ms: 1234,
  };

  const record = await outbox.enqueue(event);
  assert.equal(record.content_encoding, "gzip");
  assert.equal(record.original_size_bytes > 1024, true);
  assert.equal(record.stored_size_bytes < record.original_size_bytes, true);

  await outbox.flushAll();
  assert.equal(ingested.length, 1);
  assert.deepEqual(ingested[0].event, event);
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
    workerFactory: workerFactoryOk,
  });

  const event = {
    kind: "raw.event",
    payload: { source: "browser.level0", data: "X".repeat(2048) },
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
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({
    kind: "raw.event",
    payload: { data: "Y".repeat(2048) },
    ts_ms: 3333,
  });

  await assert.rejects(outbox.flushAll(), /corrupted gzip payload/);
  assert.equal(gapEvents.filter((event) => event.kind === "observability_gap.outbox_decompress_failed").length, 1);
});

test("unit: TTL > 7 суток переносит запись в DLQ + outbox_event_expired + метрика", async () => {
  const store = new InMemoryOutboxStore();
  const gapEvents = [];
  let nowMs = 10_000;
  const outbox = new Level0Outbox({
    store,
    ingestFn: async () => {},
    codec: nodeGzipCodec,
    emitGapFn: async (event) => gapEvents.push(event),
    now: () => nowMs,
    maxAgeMs: 1000,
    dlqRetentionMs: 100000,
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({ kind: "raw.event", payload: { id: 1 }, ts_ms: 1 });
  nowMs += 1500;
  await outbox.cleanup();

  const pending = await store.listPending();
  const dlq = await store.listDlq();
  assert.equal(pending.length, 0);
  assert.equal(dlq.length, 1);
  const expired = gapEvents.find((event) => event.kind === "observability_gap.outbox_event_expired");
  assert.ok(expired);
  assert.equal(expired.evidence.policy, "ttl_7d");
  assert.equal(outbox.metricsSnapshot().outbox_expired_total, 1);
});

test("unit: cleanup purge DLQ по retention + pruneDedupFn + таймер 300000мс", async () => {
  const store = new InMemoryOutboxStore();
  let nowMs = 20_000;
  let pruneCalled = 0;
  const timers = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async () => {},
    codec: nodeGzipCodec,
    now: () => nowMs,
    maxAgeMs: 1000,
    dlqRetentionMs: 2000,
    pruneDedupFn: async () => {
      pruneCalled += 1;
    },
    setIntervalFn: (fn, ms) => {
      timers.push({ fn, ms });
      return { fn, ms };
    },
    clearIntervalFn: () => {},
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({ kind: "raw.event", payload: { id: 2 }, ts_ms: 2 });
  nowMs += 1500;
  await outbox.cleanup(); // move to DLQ
  nowMs += 2500;
  await outbox.cleanup(); // purge DLQ

  assert.equal((await store.listDlq()).length, 0);
  assert.equal(outbox.metricsSnapshot().dlq_purged_total, 1);
  assert.equal(pruneCalled >= 2, true);

  await outbox.startCleanup();
  assert.equal(timers.length, 1);
  assert.equal(timers[0].ms, 300000);
});

test("integration: Worker unavailable -> fallback + observability_gap.worker_unavailable", async () => {
  const store = new InMemoryOutboxStore();
  const gapEvents = [];
  const ingested = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async (payload) => ingested.push(payload),
    codec: nodeGzipCodec,
    emitGapFn: async (event) => gapEvents.push(event),
    now: () => 30_000,
    workerFactory: () => {
      throw new Error("Worker API blocked by policy");
    },
  });

  await outbox.enqueue({ kind: "raw.event", payload: { data: "X".repeat(1500) }, ts_ms: 3 });
  await outbox.flushAll();
  await outbox.cleanup();

  assert.equal(ingested.length, 1);
  assert.equal(gapEvents.some((event) => event.kind === "observability_gap.worker_unavailable"), true);
});

test("integration: overflow never_drop_unacked -> reject + outbox_full + метрика", async () => {
  const store = new InMemoryOutboxStore();
  const gapEvents = [];
  const outbox = new Level0Outbox({
    store,
    ingestFn: async () => {},
    codec: nodeGzipCodec,
    emitGapFn: async (event) => gapEvents.push(event),
    now: () => 40_000,
    maxPending: 1,
    overflowPolicy: "never_drop_unacked",
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({ kind: "raw.event", payload: { id: 10 }, ts_ms: 10 });
  await assert.rejects(
    outbox.enqueue({ kind: "raw.event", payload: { id: 11 }, ts_ms: 11 }),
    /Outbox is full/
  );

  assert.equal(gapEvents.some((event) => event.kind === "observability_gap.outbox_full"), true);
  assert.equal(outbox.metricsSnapshot().outbox_rejected_total, 1);
});

test("integration: overflow drop_oldest_when_full -> drop + lossy + incident SEV1", async () => {
  const store = new InMemoryOutboxStore();
  const dqEvents = [];
  const incidents = [];
  let nowMs = 50_000;
  const outbox = new Level0Outbox({
    store,
    ingestFn: async () => {},
    codec: nodeGzipCodec,
    emitDataQualityFn: async (event) => dqEvents.push(event),
    emitIncidentFn: async (event) => incidents.push(event),
    now: () => nowMs,
    maxPending: 1,
    overflowPolicy: "drop_oldest_when_full",
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({ kind: "raw.event", payload: { id: 20 }, ts_ms: 20 });
  nowMs += 1;
  await outbox.enqueue({ kind: "raw.event", payload: { id: 21 }, ts_ms: 21 });

  const pending = await store.listPending();
  assert.equal(pending.length, 1);
  assert.equal(dqEvents.some((event) => event.kind === "data_quality.lossy_outbox_drop"), true);
  assert.equal(incidents.length, 1);
  assert.equal(incidents[0].kind, "incident.lossy_mode_active");
  assert.equal(incidents[0].severity, "SEV1");
  assert.equal(outbox.metricsSnapshot().outbox_dropped_total, 1);
});
