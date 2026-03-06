import test from "node:test";
import assert from "node:assert/strict";
import {
  compileLiveRunbook,
  createLocalStores,
  parseInvestigationDoc,
  serializeInvestigationDoc
} from "../dist/index.js";

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

test("local-stores: spatial SoA contract + binary chunk persist/load roundtrip", () => {
  const stores = createLocalStores();
  stores.setPosition("node-a", { x: 10, y: 20 }, "layout-a");
  stores.setPosition("node-b", { x: 30, y: 40 }, "layout-a");
  stores.spatialUpsertNode("node-c", { x: 50, y: 60, z: 7 });

  const node = stores.spatialGetNode("node-c");
  assert.equal(node?.x, 50);
  assert.equal(node?.y, 60);
  assert.equal(node?.z, 7);
  assert.ok(stores.spatialNodeCount() >= 3);

  const chunk = stores.spatialPersistBinaryChunk("layout-a");
  assert.ok(chunk instanceof Uint8Array);
  assert.ok(chunk.byteLength > 16);

  stores.setPosition("node-a", { x: 999, y: 999 }, "layout-a");
  const restored = stores.spatialLoadBinaryChunk(chunk);
  assert.equal(restored.layout_id, "layout-a");
  assert.equal(restored.restored, 2);

  const layout = stores.getLayout("layout-a");
  assert.equal(layout["node-a"].x, 10);
  assert.equal(layout["node-a"].y, 20);
  assert.equal(layout["node-b"].x, 30);
  assert.equal(layout["node-b"].y, 40);
});

test("local-stores: spatial picking uses grid index without full scan", () => {
  const stores = createLocalStores();
  for (let i = 0; i < 1500; i += 1) {
    stores.setPosition(`node-${i}`, { x: i % 200, y: Math.floor(i / 200) * 3 }, "layout-grid");
  }

  const indexInfo = stores.spatialBuildGridIndex("layout-grid", 16);
  assert.equal(indexInfo.indexed_nodes, 1500);
  assert.ok(indexInfo.cells > 0);

  const picked = stores.spatialPick("layout-grid", 55, 12, 12);
  assert.equal(picked.used_full_scan, false);
  assert.ok(picked.node_id);
  assert.ok(picked.examined_nodes < 1500);
  assert.ok(picked.candidate_nodes < 1500);
});

test("local-stores: deterministic layout and 2D<->3D selection sync", () => {
  const stores = createLocalStores();
  stores.setPosition("n-1", { x: 11, y: 21 }, "layout-sync");
  stores.setPosition("n-2", { x: 31, y: 41 }, "layout-sync");
  stores.setPosition("n-3", { x: 51, y: 61 }, "layout-sync");

  const firstLayout = stores.getLayout("layout-sync");
  const chunk = stores.spatialPersistBinaryChunk("layout-sync");
  stores.setPosition("n-1", { x: 999, y: 999 }, "layout-sync");
  stores.spatialLoadBinaryChunk(chunk);
  const restoredLayout = stores.getLayout("layout-sync");
  assert.deepEqual(restoredLayout, firstLayout);

  const syncA = stores.syncSelection2dTo3d(["n-3", "n-1", "n-1"]);
  assert.deepEqual(syncA.selection_2d, ["n-1", "n-3"]);
  assert.deepEqual(syncA.selection_3d, ["n-1", "n-3"]);

  const syncB = stores.syncSelection3dTo2d(["n-2", "n-1"]);
  assert.deepEqual(syncB.selection_2d, ["n-1", "n-2"]);
  assert.deepEqual(syncB.selection_3d, ["n-1", "n-2"]);
  assert.deepEqual(stores.currentSelectionSyncState(), syncB);
});

test("local-stores: GPU capability profiling selects deterministic fallback profile", () => {
  const stores = createLocalStores();
  const weak = stores.profileGpuCapability({
    renderer: "Intel(R) UHD Graphics 620",
    is_vm: true,
    vram_mb: 512
  });
  assert.equal(weak.gpu_class, "weak");
  assert.equal(weak.fallback_profile, "read-only");

  const standard = stores.profileGpuCapability({
    renderer: "Intel Iris Xe",
    is_vm: false,
    vram_mb: 2048
  });
  assert.equal(standard.gpu_class, "standard");
  assert.equal(standard.fallback_profile, "advanced");

  const strong = stores.profileGpuCapability({
    renderer: "NVIDIA RTX",
    is_vm: false,
    vram_mb: 8192
  });
  assert.equal(strong.gpu_class, "strong");
  assert.equal(strong.fallback_profile, "advanced");
});

test("local-stores: advanced flow guardrail auto-downgrades to read-only on perf breach", () => {
  const stores = createLocalStores();
  const normal = stores.applyFlowGuardrail({ p95_ms: 18, budget_ms: 50, error_count: 0 });
  assert.equal(normal.mode, "advanced");
  assert.equal(normal.downgrade_applied, false);

  const degraded = stores.applyFlowGuardrail({ p95_ms: 71, budget_ms: 50, error_count: 0 });
  assert.equal(degraded.mode, "read-only");
  assert.equal(degraded.downgrade_applied, true);
  assert.equal(stores.currentFlowComplexity(), "read-only");
});

test("local-stores: corrupted spatial chunk is rejected and does not mutate layout", () => {
  const stores = createLocalStores();
  stores.setPosition("c-1", { x: 10, y: 20 }, "layout-corrupt");
  const original = stores.getLayout("layout-corrupt");
  const chunk = stores.spatialPersistBinaryChunk("layout-corrupt");
  const corrupted = new Uint8Array(chunk);
  corrupted[0] = 255;
  corrupted[1] = 255;

  assert.throws(() => stores.spatialLoadBinaryChunk(corrupted), /spatial_chunk_/);
  assert.deepEqual(stores.getLayout("layout-corrupt"), original);
});

test("local-stores: scene scale-up benchmark remains bounded", () => {
  const stores = createLocalStores();
  const perf = stores.benchmarkFlowPanZoom(10000, 80);
  assert.ok(perf.p95_ms < 50);
});

test("local-stores: soak spatial updates keep deterministic node count", () => {
  const stores = createLocalStores();
  const layoutId = "layout-soak";
  for (let i = 0; i < 5000; i += 1) {
    stores.setPosition(`s-${i}`, { x: i % 200, y: Math.floor(i / 200) }, layoutId);
  }
  for (let round = 0; round < 20; round += 1) {
    for (let i = 0; i < 5000; i += 1) {
      stores.setPosition(`s-${i}`, { x: (i + round) % 200, y: Math.floor(i / 200) }, layoutId);
    }
  }
  const layout = stores.getLayout(layoutId);
  assert.equal(Object.keys(layout).length, 5000);
  assert.ok(stores.spatialNodeCount() >= 5000);
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

test("local-stores: sensitive payload fields are redacted before cache/index use", () => {
  const stores = createLocalStores();
  stores.cachePut({
    id: "sec-1",
    dna_id: "dna-sec",
    payload: {
      kind: "auth.login",
      severity: "info",
      password: "plain-secret",
      nested: {
        token: "raw-token",
        api_key: "api-key-value"
      }
    }
  });

  const cached = stores.cacheGet("sec-1");
  assert.equal(cached?.payload.password, "[REDACTED]");
  assert.equal(cached?.payload.nested.token, "[REDACTED]");
  assert.equal(cached?.payload.nested.api_key, "[REDACTED]");
  assert.equal(stores.analyticsCount("dna-sec"), 1);
});

test("local-stores: lineage trace path event -> evidence -> claim -> investigation", () => {
  const stores = createLocalStores();
  const trace = stores.traceEvidenceLineagePath({
    event_id: "evt-1",
    evidence_id: "ev-1",
    claim_id: "claim-1",
    investigation_id: "inv-1",
    evidence_lineage_id: "lin-1"
  });
  assert.equal(trace.ok, true);
  assert.deepEqual(trace.path, [
    "event:evt-1",
    "evidence:ev-1",
    "claim:claim-1",
    "investigation:inv-1",
    "lineage:lin-1"
  ]);
});

test("local-stores: investigation parser/serializer produce deterministic canonical output", () => {
  const docA = {
    doc_id: "inv-1",
    version: "v1",
    claims: [{ b: 2, a: 1 }],
    decisions: [{ text: "do" }],
    actions: [{ action_id: "act-1" }],
    results: [{ result_id: "res-1" }],
    evidence_refs: ["ev-1"],
    audit_refs: ["aud-1"]
  };
  const docB = {
    version: "v1",
    doc_id: "inv-1",
    actions: [{ action_id: "act-1" }],
    claims: [{ a: 1, b: 2 }],
    decisions: [{ text: "do" }],
    results: [{ result_id: "res-1" }],
    audit_refs: ["aud-1"],
    evidence_refs: ["ev-1"]
  };

  const canonicalA = serializeInvestigationDoc(docA);
  const canonicalB = serializeInvestigationDoc(docB);
  assert.equal(canonicalA, canonicalB);
  assert.equal(parseInvestigationDoc(canonicalA).doc_id, "inv-1");
});

test("local-stores: parser rejects investigation doc with missing required fields", () => {
  assert.throws(() => parseInvestigationDoc("{\"doc_id\":\"inv-2\"}"), /investigation_doc_missing_field/);
});

test("local-stores: fork/replay/compare investigation docs integration", () => {
  const stores = createLocalStores();
  const imported = stores.importInvestigationDoc({
    doc_id: "inv-a",
    version: "v1",
    claims: [{ claim_id: "c1", statement: "s1", evidence_refs: ["ev-1"] }],
    decisions: [{ decision_id: "d1", text: "t1" }],
    actions: [{ action_id: "a1", kind: "noop" }],
    results: [{ result_id: "r1", action_id: "a1" }],
    evidence_refs: ["ev-1"],
    audit_refs: ["au-1"]
  });
  assert.equal(imported.doc_id, "inv-a");

  const forked = stores.forkInvestigationDoc("inv-a", "inv-a-fork");
  assert.equal(forked?.doc_id, "inv-a-fork");

  const replay = stores.replayInvestigationDoc("inv-a-fork");
  assert.equal(replay.ok, true);
  assert.ok(replay.steps.includes("claims:1"));

  const compare = stores.compareInvestigationDocs("inv-a", "inv-a-fork");
  assert.equal(compare?.deltas.claims, 0);
  assert.equal(compare?.deltas.actions, 0);
  assert.equal(compare?.same_signature, false);
});

test("local-stores: backward compatibility for investigation docs keeps replay operable", () => {
  const stores = createLocalStores();
  const legacyDoc = {
    doc_id: "inv-legacy",
    version: "v1",
    claims: [{ claim_id: "c1", statement: "legacy", evidence_refs: ["ev-1"] }],
    decisions: [],
    actions: [],
    results: [],
    evidence_refs: ["ev-1"],
    audit_refs: [],
    legacy_field: "kept-for-compat"
  };
  stores.importInvestigationDoc(legacyDoc);
  const exported = stores.exportInvestigationDoc("inv-legacy");
  assert.equal(exported?.doc_id, "inv-legacy");
  assert.equal(exported?.version, "v1");
  assert.equal(stores.replayInvestigationDoc("inv-legacy").ok, true);
});

test("local-stores: LRC compiles runbook into condition graph and marks invalid steps", () => {
  const compiled = compileLiveRunbook(
    {
      runbook_id: "rb-1",
      steps: [
        { step_id: "s1", title: "Check queue", requires_evidence_refs: ["ev-1"] },
        { step_id: "s2", title: "Verify rollback window", requires_evidence_refs: ["ev-2", "ev-3"] }
      ]
    },
    ["ev-1", "ev-3"]
  );
  assert.equal(compiled.graph.length, 2);
  assert.deepEqual(compiled.invalid_steps, ["s2"]);
  assert.equal(compiled.graph[0].status, "valid");
  assert.equal(compiled.graph[1].status, "invalid");
  assert.deepEqual(compiled.graph[1].missing_evidence_refs, ["ev-2"]);
});

test("local-stores: investigation library cycle import -> list -> verify -> replay", () => {
  const stores = createLocalStores();
  stores.importInvestigationDoc({
    doc_id: "inv-cycle",
    version: "v1",
    claims: [{ claim_id: "c1", statement: "cycle", evidence_refs: ["ev-1"] }],
    decisions: [{ decision_id: "d1", text: "cycle-decision" }],
    actions: [{ action_id: "a1", kind: "noop" }],
    results: [{ result_id: "r1", action_id: "a1" }],
    evidence_refs: ["ev-1"],
    audit_refs: ["aud-1"]
  });

  const listed = stores.listInvestigationDocs();
  assert.equal(listed.length, 1);
  assert.equal(listed[0].doc_id, "inv-cycle");

  const exported = stores.exportInvestigationDoc("inv-cycle");
  assert.equal(exported?.doc_id, "inv-cycle");

  const verified = stores.verifyInvestigationDoc("inv-cycle");
  assert.equal(verified.ok, true);

  const replayed = stores.replayInvestigationDoc("inv-cycle");
  assert.equal(replayed.ok, true);
  assert.ok(replayed.steps.includes("actions:1"));
});

test("local-stores: investigation doc replay keeps attached audit proof refs", () => {
  const stores = createLocalStores();
  stores.importInvestigationDoc({
    doc_id: "inv-proof",
    version: "v1",
    claims: [],
    decisions: [],
    actions: [],
    results: [],
    evidence_refs: ["ev-1"],
    audit_refs: ["aud-1"],
    proof_refs: ["proof://merkle/aud-1"]
  });
  const replayed = stores.replayInvestigationDoc("inv-proof");
  assert.equal(replayed.ok, true);
  assert.ok(replayed.steps.includes("proof_refs:1"));
});
