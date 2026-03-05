import { dedupKeyForEvent } from "./level0_multitab.js";

const DEFAULT_THRESHOLD_BYTES = 1024;

function ensureCrypto() {
  if (!globalThis.crypto || !globalThis.crypto.subtle) {
    throw new Error("Web Crypto API is required");
  }
  return globalThis.crypto;
}

function toUint8Array(input) {
  if (input instanceof Uint8Array) {
    return input;
  }
  if (input instanceof ArrayBuffer) {
    return new Uint8Array(input);
  }
  throw new Error("Codec result must be Uint8Array or ArrayBuffer");
}

async function gzipWithCompressionStream(bytes) {
  if (typeof CompressionStream !== "function") {
    throw new Error("CompressionStream is unavailable");
  }
  const stream = new Blob([bytes]).stream().pipeThrough(new CompressionStream("gzip"));
  const buffer = await new Response(stream).arrayBuffer();
  return new Uint8Array(buffer);
}

async function gunzipWithDecompressionStream(bytes) {
  if (typeof DecompressionStream !== "function") {
    throw new Error("DecompressionStream is unavailable");
  }
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
  const buffer = await new Response(stream).arrayBuffer();
  return new Uint8Array(buffer);
}

export const browserGzipCodec = {
  gzip: gzipWithCompressionStream,
  gunzip: gunzipWithDecompressionStream,
};

export class InMemoryOutboxStore {
  constructor() {
    this._records = [];
  }

  async put(record) {
    this._records.push(record);
  }

  async list() {
    return [...this._records];
  }

  async deleteById(id) {
    this._records = this._records.filter((record) => record.id !== id);
  }
}

export class Level0Outbox {
  constructor({
    store,
    ingestFn,
    codec = browserGzipCodec,
    emitGapFn = async () => {},
    now = () => Date.now(),
    ingestEndpoint = "/api/v1/ingest",
    browserOrigin = globalThis.location?.origin || "unknown",
    compressionThresholdBytes = DEFAULT_THRESHOLD_BYTES,
  }) {
    this._store = store;
    this._ingestFn = ingestFn;
    this._codec = codec;
    this._emitGapFn = emitGapFn;
    this._now = now;
    this._ingestEndpoint = ingestEndpoint;
    this._browserOrigin = browserOrigin;
    this._compressionThresholdBytes = compressionThresholdBytes;
  }

  async enqueue(event) {
    const payloadJson = JSON.stringify(event);
    const payloadBytes = new TextEncoder().encode(payloadJson);
    const originalSizeBytes = payloadBytes.byteLength;
    const useGzip = originalSizeBytes > this._compressionThresholdBytes;
    let contentEncoding = "identity";
    let storedBytes = payloadBytes;

    if (useGzip) {
      storedBytes = toUint8Array(await this._codec.gzip(payloadBytes));
      contentEncoding = "gzip";
    }

    const record = {
      id: ensureCrypto().randomUUID(),
      created_at_ms: this._now(),
      dedup_key: await dedupKeyForEvent(event),
      content_encoding: contentEncoding,
      original_size_bytes: originalSizeBytes,
      stored_size_bytes: storedBytes.byteLength,
      payload_bytes: storedBytes,
    };
    await this._store.put(record);
    return record;
  }

  async flushAll() {
    const records = await this._store.list();
    for (const record of records) {
      const event = await this._decodeRecord(record);
      await this._ingestFn({
        event,
        dedup_key: record.dedup_key,
        content_encoding: record.content_encoding,
        original_size_bytes: record.original_size_bytes,
        stored_size_bytes: record.stored_size_bytes,
      });
      await this._store.deleteById(record.id);
    }
  }

  async _decodeRecord(record) {
    try {
      const payloadBytes = toUint8Array(record.payload_bytes);
      let rawBytes = payloadBytes;
      if (record.content_encoding === "gzip") {
        rawBytes = toUint8Array(await this._codec.gunzip(payloadBytes));
      }
      const json = new TextDecoder().decode(rawBytes);
      return JSON.parse(json);
    } catch (error) {
      await this._emitGapFn(this._buildDecompressFailedEvent(record, error));
      throw error;
    }
  }

  _buildDecompressFailedEvent(record, error) {
    return {
      kind: "observability_gap.outbox_decompress_failed",
      ts_ms: this._now(),
      trace_id: ensureCrypto().randomUUID(),
      what: "Outbox payload decompression failed",
      where: "browser.outbox.flush",
      why: "gzip_decompress_failed",
      evidence: {
        dedup_key: record.dedup_key,
        endpoint: this._ingestEndpoint,
        browser_origin: this._browserOrigin,
        error: String(error?.message || error || "unknown"),
      },
      actions: [
        {
          rel: "runbook",
          action_ref: "docs/runbooks/outbox_decompress_failed.md",
          description: "Проверить outbox payload и целостность gzip.",
        },
      ],
    };
  }
}

export const outboxCompressionConfig = {
  thresholdBytes: DEFAULT_THRESHOLD_BYTES,
  codec: "gzip",
};
