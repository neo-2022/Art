import test from "node:test";
import assert from "node:assert/strict";
import { createLocalStores } from "../dist/index.js";

test("local-stores: cache and dna lookup", () => {
  const stores = createLocalStores();
  stores.cachePut({ id: "1", dna_id: "dna-a", payload: { a: 1 } });
  stores.cachePut({ id: "2", dna_id: "dna-a", payload: { a: 2 } });
  stores.cachePut({ id: "3", dna_id: "dna-b", payload: { b: 1 } });

  assert.equal(stores.cacheGet("1")?.dna_id, "dna-a");
  assert.equal(stores.findSimilarByDna("dna-a").length, 2);
  assert.equal(stores.analyticsCount("dna-a"), 2);
  assert.equal(stores.spatialStoreStub().status, "stubbed");
  assert.ok(stores.spatialStoreStub().interface.includes("saveSnapshot"));
});

test("local-stores: analytics summary returns charts and instructions", () => {
  const stores = createLocalStores();
  const now = Date.now();
  stores.recordTelemetry({
    ts_ms: now - 30_000,
    severity: "error",
    kind: "db.timeout",
    dna_id: "dna-orders"
  });
  stores.recordTelemetry({
    ts_ms: now - 20_000,
    severity: "warn",
    kind: "cache.degraded",
    dna_id: "dna-orders"
  });
  stores.recordTelemetry({
    ts_ms: now - 10_000,
    severity: "error",
    kind: "observability_gap.stream_lag",
    is_gap: true
  });

  const summary = stores.analyticsSummary(120, 3);
  assert.equal(summary.totals.total_events, 3);
  assert.equal(summary.totals.gap_events, 1);
  assert.ok(summary.charts.timeline.length >= 1);
  assert.ok(summary.charts.top_kinds.length >= 1);
  assert.ok(summary.instructions.length >= 1);
});
