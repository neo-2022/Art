import { dedupKeyForEvent } from "./level0_multitab.js";

const DEFAULT_THRESHOLD_BYTES = 1024;
const OUTBOX_MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;
const DLQ_RETENTION_MS = 30 * 24 * 60 * 60 * 1000;
const CLEANUP_INTERVAL_MS = 300000;

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

function collectBrowserDetails() {
  if (globalThis.navigator && globalThis.navigator.userAgent) {
    return String(globalThis.navigator.userAgent);
  }
  return "unknown";
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

class WorkerFirstExecutor {
  constructor({ workerFactory, emitGapFn, now, browserDetails }) {
    this._workerFactory = workerFactory || (() => {
      if (typeof Worker !== "function") {
        throw new Error("Worker API is unavailable");
      }
      return {
        async execute(_operationName, runOnMainThread) {
          return runOnMainThread();
        },
      };
    });
    this._emitGapFn = emitGapFn;
    this._now = now;
    this._browserDetails = browserDetails;
    this._worker = null;
  }

  async run(operationName, runOnMainThread) {
    try {
      if (!this._worker) {
        this._worker = this._workerFactory();
      }
      if (!this._worker || typeof this._worker.execute !== "function") {
        throw new Error("Worker executor is unavailable");
      }
      return await this._worker.execute(operationName, runOnMainThread);
    } catch (error) {
      if (!this._isWorkerPathError(error)) {
        throw error;
      }
      await this._emitGapFn({
        kind: "observability_gap.worker_unavailable",
        ts_ms: this._now(),
        trace_id: ensureCrypto().randomUUID(),
        what: "Worker path unavailable, switched to main-thread fallback",
        where: "browser.level0.worker",
        why: "worker_init_or_execute_failed",
        evidence: {
          reason: String(error?.message || error || "unknown"),
          browser_details: this._browserDetails,
        },
        actions: [
          {
            rel: "runbook",
            action_ref: "docs/runbooks/worker_unavailable.md",
            description: "Проверить Worker API и окружение браузера.",
          },
        ],
      });
      return runOnMainThread();
    }
  }

  _isWorkerPathError(error) {
    const message = String(error?.message || error || "");
    if (/Worker API|worker unavailable|worker executor|worker path|worker/i.test(message)) {
      return true;
    }
    return false;
  }
}

export class InMemoryOutboxStore {
  constructor() {
    this._pending = [];
    this._dlq = [];
  }

  async putPending(record) {
    this._pending.push(record);
  }

  async listPending() {
    return [...this._pending];
  }

  async deletePendingById(id) {
    this._pending = this._pending.filter((record) => record.id !== id);
  }

  async countPending() {
    return this._pending.length;
  }

  async shiftOldestPending() {
    if (this._pending.length === 0) {
      return null;
    }
    let oldestIndex = 0;
    for (let i = 1; i < this._pending.length; i += 1) {
      if (this._pending[i].created_at_ms < this._pending[oldestIndex].created_at_ms) {
        oldestIndex = i;
      }
    }
    const [record] = this._pending.splice(oldestIndex, 1);
    return record || null;
  }

  async putDlq(record) {
    this._dlq.push(record);
  }

  async listDlq() {
    return [...this._dlq];
  }

  async deleteDlqById(id) {
    this._dlq = this._dlq.filter((record) => record.id !== id);
  }
}

export class Level0Outbox {
  constructor({
    store,
    ingestFn,
    codec = browserGzipCodec,
    emitGapFn = async () => {},
    emitDataQualityFn = async () => {},
    emitIncidentFn = async () => {},
    now = () => Date.now(),
    ingestEndpoint = "/api/v1/ingest",
    browserOrigin = globalThis.location?.origin || "unknown",
    browserDetails = collectBrowserDetails(),
    compressionThresholdBytes = DEFAULT_THRESHOLD_BYTES,
    maxAgeMs = OUTBOX_MAX_AGE_MS,
    dlqRetentionMs = DLQ_RETENTION_MS,
    maxPending = 1000,
    overflowPolicy = "never_drop_unacked",
    workerFactory,
    setIntervalFn = globalThis.setInterval?.bind(globalThis),
    clearIntervalFn = globalThis.clearInterval?.bind(globalThis),
    pruneDedupFn = async () => {},
  }) {
    this._store = store;
    this._ingestFn = ingestFn;
    this._codec = codec;
    this._emitGapFn = emitGapFn;
    this._emitDataQualityFn = emitDataQualityFn;
    this._emitIncidentFn = emitIncidentFn;
    this._now = now;
    this._ingestEndpoint = ingestEndpoint;
    this._browserOrigin = browserOrigin;
    this._browserDetails = browserDetails;
    this._compressionThresholdBytes = compressionThresholdBytes;
    this._maxAgeMs = maxAgeMs;
    this._dlqRetentionMs = dlqRetentionMs;
    this._maxPending = maxPending;
    this._overflowPolicy = overflowPolicy;
    this._setIntervalFn = setIntervalFn;
    this._clearIntervalFn = clearIntervalFn;
    this._pruneDedupFn = pruneDedupFn;
    this._cleanupTimer = null;
    this._metrics = {
      outbox_rejected_total: 0,
      outbox_dropped_total: 0,
      outbox_expired_total: 0,
      dlq_purged_total: 0,
    };
    this._executor = new WorkerFirstExecutor({
      workerFactory,
      emitGapFn,
      now,
      browserDetails,
    });
  }

  metricsSnapshot() {
    return { ...this._metrics };
  }

  async enqueue(event) {
    return this._executor.run("enqueue", async () => {
      await this._applyOverflowPolicyIfNeeded();

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
      await this._store.putPending(record);
      return record;
    });
  }

  async flushAll() {
    return this._executor.run("flushAll", async () => {
      const records = await this._store.listPending();
      for (const record of records) {
        const event = await this._decodeRecord(record);
        await this._ingestFn({
          event,
          dedup_key: record.dedup_key,
          content_encoding: record.content_encoding,
          original_size_bytes: record.original_size_bytes,
          stored_size_bytes: record.stored_size_bytes,
        });
        await this._store.deletePendingById(record.id);
      }
    });
  }

  async cleanup() {
    return this._executor.run("cleanup", async () => {
      const nowMs = this._now();

      const pending = await this._store.listPending();
      for (const record of pending) {
        const ageMs = nowMs - record.created_at_ms;
        if (ageMs > this._maxAgeMs) {
          await this._store.deletePendingById(record.id);
          await this._store.putDlq({
            ...record,
            moved_to_dlq_at_ms: nowMs,
            dlq_reason: "ttl_expired",
          });
          this._metrics.outbox_expired_total += 1;
          await this._emitGapFn(this._buildOutboxExpiredEvent(record, ageMs));
        }
      }

      const dlq = await this._store.listDlq();
      for (const record of dlq) {
        const baseTs = record.moved_to_dlq_at_ms || record.created_at_ms;
        const ageMs = nowMs - baseTs;
        if (ageMs > this._dlqRetentionMs) {
          await this._store.deleteDlqById(record.id);
          this._metrics.dlq_purged_total += 1;
        }
      }

      await this._pruneDedupFn();
    });
  }

  async startCleanup() {
    await this.cleanup();
    if (typeof this._setIntervalFn !== "function") {
      return;
    }
    this._cleanupTimer = this._setIntervalFn(() => {
      void this.cleanup();
    }, CLEANUP_INTERVAL_MS);
  }

  stopCleanup() {
    if (this._cleanupTimer && typeof this._clearIntervalFn === "function") {
      this._clearIntervalFn(this._cleanupTimer);
    }
    this._cleanupTimer = null;
  }

  async _applyOverflowPolicyIfNeeded() {
    const pendingCount = await this._store.countPending();
    if (pendingCount < this._maxPending) {
      return;
    }

    if (this._overflowPolicy === "never_drop_unacked") {
      this._metrics.outbox_rejected_total += 1;
      await this._emitGapFn({
        kind: "observability_gap.outbox_full",
        ts_ms: this._now(),
        trace_id: ensureCrypto().randomUUID(),
        what: "Outbox is full in never_drop_unacked policy",
        where: "browser.outbox.enqueue",
        why: "capacity_limit",
        evidence: {
          limit: this._maxPending,
          pending_count: pendingCount,
          endpoint: this._ingestEndpoint,
        },
        actions: [
          {
            rel: "runbook",
            action_ref: "docs/runbooks/outbox_full.md",
            description: "Разгрузить outbox или увеличить лимит.",
          },
        ],
      });
      throw new Error("Outbox is full (never_drop_unacked)");
    }

    if (this._overflowPolicy === "drop_oldest_when_full") {
      const dropped = await this._store.shiftOldestPending();
      if (dropped) {
        this._metrics.outbox_dropped_total += 1;
        await this._store.putDlq({
          ...dropped,
          moved_to_dlq_at_ms: this._now(),
          dlq_reason: "overflow_drop_oldest",
        });
        await this._emitDataQualityFn({
          kind: "data_quality.lossy_outbox_drop",
          ts_ms: this._now(),
          trace_id: ensureCrypto().randomUUID(),
          what: "Oldest outbox event dropped due to overflow policy",
          where: "browser.outbox.enqueue",
          why: "drop_oldest_when_full",
          evidence: {
            dropped_dedup_key: dropped.dedup_key,
            limit: this._maxPending,
            pending_count: pendingCount,
          },
          actions: [
            {
              rel: "runbook",
              action_ref: "docs/runbooks/lossy_mode_active.md",
              description: "Проверить lossy режим и восстановить доставку.",
            },
          ],
        });
        await this._emitIncidentFn({
          kind: "incident.lossy_mode_active",
          ts_ms: this._now(),
          severity: "SEV1",
          trace_id: ensureCrypto().randomUUID(),
          action_ref: "docs/runbooks/lossy_mode_active.md",
        });
      }
      return;
    }

    throw new Error(`Unsupported overflow policy: ${this._overflowPolicy}`);
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

  _buildOutboxExpiredEvent(record, ageMs) {
    return {
      kind: "observability_gap.outbox_event_expired",
      ts_ms: this._now(),
      trace_id: ensureCrypto().randomUUID(),
      what: "Outbox event expired by TTL policy",
      where: "browser.outbox.cleanup",
      why: "ttl_7d",
      evidence: {
        dedup_key: record.dedup_key,
        age_ms: ageMs,
        policy: "ttl_7d",
      },
      actions: [
        {
          rel: "runbook",
          action_ref: "docs/runbooks/outbox_event_expired.md",
          description: "Проверить backlog и связь с ingest.",
        },
      ],
    };
  }
}

export const outboxCompressionConfig = {
  thresholdBytes: DEFAULT_THRESHOLD_BYTES,
  codec: "gzip",
};

export const outboxRuntimeConfig = {
  maxAgeMs: OUTBOX_MAX_AGE_MS,
  dlqRetentionMs: DLQ_RETENTION_MS,
  cleanupIntervalMs: CLEANUP_INTERVAL_MS,
  overflowPolicies: ["never_drop_unacked", "drop_oldest_when_full"],
};
