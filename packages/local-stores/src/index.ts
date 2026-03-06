export interface CachedEvent {
  id: string;
  dna_id: string;
  payload: Record<string, unknown>;
}

export interface StoreTelemetryRecord {
  ts_ms: number;
  severity: string;
  kind: string;
  dna_id?: string;
  is_gap?: boolean;
}

export interface StoreTopItem {
  key: string;
  count: number;
  share_pct: number;
}

export interface StoreTimelinePoint {
  minute_ts_ms: number;
  total_events: number;
  gap_events: number;
}

export interface StoreInstruction {
  id: string;
  priority: "low" | "medium" | "high";
  title: string;
  description: string;
}

export type TruthMode = "observed" | "derived" | "predicted";

export type FlowSemanticType =
  | "dna_cloud"
  | "incident_cloud"
  | "gap_cloud"
  | "service_node"
  | "store_node"
  | "buffer_node"
  | "agent_node";

export interface FlowNode {
  node_id: string;
  type: FlowSemanticType;
  label: string;
  truth_mode: TruthMode;
  evidence_refs: string[];
  severity: "low" | "medium" | "high" | "critical";
  confidence?: number;
}

export interface FlowEdge {
  edge_id: string;
  from_node_id: string;
  to_node_id: string;
  throughput: number;
}

export interface FlowScene {
  generated_at_ms: number;
  nodes: FlowNode[];
  edges: FlowEdge[];
}

export interface Vec2 {
  x: number;
  y: number;
}

export type FlowComplexity = "read-only" | "advanced";

export interface FlowSnapshotState {
  layout_id: string;
  positions: Record<string, Vec2>;
  visibility: Record<string, boolean>;
  lod: "low" | "standard" | "high";
  flow_complexity: FlowComplexity;
}

export interface InvestigationDoc {
  doc_id: string;
  version: string;
  claims: Array<Record<string, unknown>>;
  decisions: Array<Record<string, unknown>>;
  actions: Array<Record<string, unknown>>;
  results: Array<Record<string, unknown>>;
  evidence_refs: string[];
  audit_refs: string[];
  signature?: string;
}

export interface InvestigationLibraryItem {
  doc_id: string;
  version: string;
  signature: string;
  imported_at_ms: number;
  claim_count: number;
  action_count: number;
}

const FLOW_TYPES: FlowSemanticType[] = [
  "dna_cloud",
  "incident_cloud",
  "gap_cloud",
  "service_node",
  "store_node",
  "buffer_node",
  "agent_node"
];

function minuteBucket(tsMs: number): number {
  return Math.floor(tsMs / 60_000) * 60_000;
}

function topItems(counts: Map<string, number>, total: number, top: number): StoreTopItem[] {
  return [...counts.entries()]
    .sort((left, right) => (right[1] - left[1]) || left[0].localeCompare(right[0]))
    .slice(0, top)
    .map(([key, count]) => ({
      key,
      count,
      share_pct: total === 0 ? 0 : Math.round((count / total) * 10_000) / 100
    }));
}

function stableStringify(value: unknown): string {
  if (value === null || value === undefined) {
    return "null";
  }
  if (typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }
  const objectValue = value as Record<string, unknown>;
  const keys = Object.keys(objectValue).sort();
  const body = keys
    .map((key) => `${JSON.stringify(key)}:${stableStringify(objectValue[key])}`)
    .join(",");
  return `{${body}}`;
}

function simpleHash(input: string): string {
  let hash = 2166136261;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return `h${(hash >>> 0).toString(16).padStart(8, "0")}`;
}

function cloneSnapshotState(state: FlowSnapshotState): FlowSnapshotState {
  return {
    layout_id: state.layout_id,
    positions: Object.fromEntries(
      Object.entries(state.positions).map(([nodeId, vec]) => [nodeId, { x: vec.x, y: vec.y }])
    ),
    visibility: { ...state.visibility },
    lod: state.lod,
    flow_complexity: state.flow_complexity
  };
}

function defaultFlowSnapshot(layoutId = "default"): FlowSnapshotState {
  return {
    layout_id: layoutId,
    positions: {},
    visibility: {},
    lod: "standard",
    flow_complexity: "advanced"
  };
}

export function createLocalStores() {
  const cache = new Map<string, CachedEvent>();
  const analyticsCounters = new Map<string, number>();
  const timeline = new Map<number, { total_events: number; gap_events: number }>();
  const severityCounters = new Map<string, number>();
  const kindCounters = new Map<string, number>();
  const dnaCounters = new Map<string, number>();
  const layoutStore = new Map<string, Map<string, Vec2>>();
  const snapshots = new Map<string, FlowSnapshotState>();
  const investigationStore = new Map<string, InvestigationDoc>();
  const investigationMeta = new Map<string, InvestigationLibraryItem>();
  let flowComplexity: FlowComplexity = "advanced";
  let totalEvents = 0;
  let gapEvents = 0;

  function ensureLayout(layoutId: string): Map<string, Vec2> {
    const existing = layoutStore.get(layoutId);
    if (existing) {
      return existing;
    }
    const created = new Map<string, Vec2>();
    layoutStore.set(layoutId, created);
    return created;
  }

  function recordTelemetry(input: StoreTelemetryRecord): void {
    const minute = minuteBucket(input.ts_ms);
    const bucket = timeline.get(minute) || { total_events: 0, gap_events: 0 };
    bucket.total_events += 1;
    if (input.is_gap) {
      bucket.gap_events += 1;
      gapEvents += 1;
    }
    timeline.set(minute, bucket);
    totalEvents += 1;

    severityCounters.set(input.severity, (severityCounters.get(input.severity) || 0) + 1);
    kindCounters.set(input.kind, (kindCounters.get(input.kind) || 0) + 1);
    if (input.dna_id) {
      dnaCounters.set(input.dna_id, (dnaCounters.get(input.dna_id) || 0) + 1);
    }
  }

  function buildInstructions(
    topKinds: StoreTopItem[],
    topDna: StoreTopItem[],
    gapRatePct: number
  ): StoreInstruction[] {
    const out: StoreInstruction[] = [];
    if (gapRatePct > 5) {
      out.push({
        id: "gap-rate-high",
        priority: "high",
        title: "High gap rate",
        description: `Gap rate is ${gapRatePct.toFixed(2)}%. Stabilize collection pipeline first.`
      });
    }
    if (topKinds[0]) {
      out.push({
        id: "top-kind-focus",
        priority: "medium",
        title: "Top incident pattern",
        description: `Most frequent kind is '${topKinds[0].key}'. Create focused remediation instructions.`
      });
    }
    if (topDna[0]) {
      out.push({
        id: "top-dna-focus",
        priority: "medium",
        title: "Recurring DNA cluster",
        description: `DNA '${topDna[0].key}' repeats frequently. Prioritize investigation-as-code.`
      });
    }
    if (out.length === 0) {
      out.push({
        id: "stable-signal",
        priority: "low",
        title: "Stable signal quality",
        description: "No critical anomalies. Keep monitoring trend and replay checks."
      });
    }
    return out;
  }

  function buildFlowScene(): FlowScene {
    const nodes: FlowNode[] = FLOW_TYPES.map((type, index) => {
      let truthMode: TruthMode = "observed";
      if (type === "dna_cloud") {
        truthMode = "derived";
      } else if (type === "gap_cloud") {
        truthMode = "predicted";
      }
      return {
        node_id: `${type}-${index + 1}`,
        type,
        label: type,
        truth_mode: truthMode,
        evidence_refs: [`ev-flow-${index + 1}`],
        severity: index % 4 === 0 ? "high" : "medium",
        confidence: truthMode === "predicted" ? 0.72 : undefined
      };
    });

    const edges: FlowEdge[] = nodes.slice(0, -1).map((node, index) => ({
      edge_id: `edge-${index + 1}`,
      from_node_id: node.node_id,
      to_node_id: nodes[index + 1].node_id,
      throughput: 100 - index * 7
    }));

    return {
      generated_at_ms: Date.now(),
      nodes,
      edges
    };
  }

  function importInvestigationDoc(input: InvestigationDoc): InvestigationLibraryItem {
    const signature = input.signature || simpleHash(stableStringify(input));
    const normalized: InvestigationDoc = {
      ...input,
      signature
    };
    investigationStore.set(input.doc_id, normalized);
    const item: InvestigationLibraryItem = {
      doc_id: input.doc_id,
      version: input.version,
      signature,
      imported_at_ms: Date.now(),
      claim_count: input.claims.length,
      action_count: input.actions.length
    };
    investigationMeta.set(input.doc_id, item);
    return item;
  }

  return {
    cachePut(event: CachedEvent): void {
      cache.set(event.id, event);
      analyticsCounters.set(event.dna_id, (analyticsCounters.get(event.dna_id) || 0) + 1);
      recordTelemetry({
        ts_ms: Date.now(),
        severity: String(event.payload["severity"] || "unknown"),
        kind: String(event.payload["kind"] || "unknown"),
        dna_id: event.dna_id,
        is_gap: String(event.payload["kind"] || "").startsWith("observability_gap.")
      });
    },
    cacheGet(id: string): CachedEvent | null {
      return cache.get(id) || null;
    },
    findSimilarByDna(dnaId: string): CachedEvent[] {
      const out: CachedEvent[] = [];
      for (const value of cache.values()) {
        if (value.dna_id === dnaId) {
          out.push(value);
        }
      }
      return out;
    },
    analyticsCount(dnaId: string): number {
      return analyticsCounters.get(dnaId) || 0;
    },
    recordTelemetry,
    analyticsSummary(windowMinutes = 60, top = 5) {
      const now = Date.now();
      const cutoff = now - (windowMinutes * 60_000);
      const timelinePoints: StoreTimelinePoint[] = [...timeline.entries()]
        .filter(([minute]) => minute >= cutoff)
        .sort((left, right) => left[0] - right[0])
        .map(([minute, bucket]) => ({
          minute_ts_ms: minute,
          total_events: bucket.total_events,
          gap_events: bucket.gap_events
        }));

      const severity = topItems(severityCounters, totalEvents, top);
      const topKinds = topItems(kindCounters, totalEvents, top);
      const topDna = topItems(dnaCounters, totalEvents, top);
      const gapRatePct = totalEvents === 0 ? 0 : Math.round((gapEvents / totalEvents) * 10_000) / 100;

      return {
        totals: {
          total_events: totalEvents,
          gap_events: gapEvents,
          gap_rate_pct: gapRatePct
        },
        charts: {
          timeline: timelinePoints,
          severity_distribution: severity,
          top_kinds: topKinds,
          top_dna: topDna
        },
        instructions: buildInstructions(topKinds, topDna, gapRatePct)
      };
    },
    flowNodeTypes(): FlowSemanticType[] {
      return [...FLOW_TYPES];
    },
    buildFlowScene,
    inspectFlowNode(nodeId: string): { node_id: string; evidence_refs: string[]; lineage: string[] } | null {
      const scene = buildFlowScene();
      const node = scene.nodes.find((item) => item.node_id === nodeId);
      if (!node) {
        return null;
      }
      return {
        node_id: node.node_id,
        evidence_refs: [...node.evidence_refs],
        lineage: [
          `node:${node.node_id}`,
          `truth:${node.truth_mode}`,
          `evidence:${node.evidence_refs.join(",")}`
        ]
      };
    },
    setPosition(nodeId: string, vec: Vec2, layoutId = "default"): void {
      const layout = ensureLayout(layoutId);
      layout.set(nodeId, { x: vec.x, y: vec.y });
    },
    getLayout(layoutId = "default"): Record<string, Vec2> {
      const layout = ensureLayout(layoutId);
      return Object.fromEntries([...layout.entries()].map(([nodeId, vec]) => [nodeId, { x: vec.x, y: vec.y }]));
    },
    saveSnapshot(snapshotId: string, state: FlowSnapshotState): void {
      snapshots.set(snapshotId, cloneSnapshotState(state));
    },
    loadSnapshot(snapshotId: string): FlowSnapshotState | null {
      const state = snapshots.get(snapshotId);
      return state ? cloneSnapshotState(state) : null;
    },
    listSnapshots(): string[] {
      return [...snapshots.keys()].sort();
    },
    applyFlowGuardrail(metrics: { p95_ms: number; budget_ms: number; error_count: number }): {
      mode: FlowComplexity;
      downgrade_applied: boolean;
    } {
      const shouldDowngrade = metrics.p95_ms > metrics.budget_ms || metrics.error_count > 0;
      if (shouldDowngrade) {
        flowComplexity = "read-only";
        return { mode: flowComplexity, downgrade_applied: true };
      }
      flowComplexity = "advanced";
      return { mode: flowComplexity, downgrade_applied: false };
    },
    currentFlowComplexity(): FlowComplexity {
      return flowComplexity;
    },
    importInvestigationDoc,
    listInvestigationDocs(): InvestigationLibraryItem[] {
      return [...investigationMeta.values()].sort((left, right) => left.doc_id.localeCompare(right.doc_id));
    },
    exportInvestigationDoc(docId: string): InvestigationDoc | null {
      const doc = investigationStore.get(docId);
      if (!doc) {
        return null;
      }
      return JSON.parse(stableStringify(doc)) as InvestigationDoc;
    },
    verifyInvestigationDoc(docId: string): { ok: boolean; expected: string; actual: string } {
      const doc = investigationStore.get(docId);
      if (!doc) {
        return { ok: false, expected: "", actual: "" };
      }
      const expected = simpleHash(stableStringify({ ...doc, signature: undefined }));
      const actual = doc.signature || "";
      return {
        ok: expected === actual,
        expected,
        actual
      };
    },
    replayInvestigationDoc(docId: string): { ok: boolean; steps: string[] } {
      const doc = investigationStore.get(docId);
      if (!doc) {
        return { ok: false, steps: [] };
      }
      const steps = [
        `claims:${doc.claims.length}`,
        `decisions:${doc.decisions.length}`,
        `actions:${doc.actions.length}`,
        `results:${doc.results.length}`,
        `evidence_refs:${doc.evidence_refs.length}`,
        `audit_refs:${doc.audit_refs.length}`
      ];
      return { ok: true, steps };
    },
    spatialStoreStub() {
      return {
        status: "stubbed",
        model: "typed-array-contract",
        interface: ["setPosition", "getLayout", "saveSnapshot", "loadSnapshot", "listSnapshots"]
      } as const;
    },
    benchmarkFlowPanZoom(nodeCount: number, frames = 50): { p95_ms: number; samples_ms: number[] } {
      const positions: Vec2[] = [];
      for (let i = 0; i < nodeCount; i += 1) {
        positions.push({ x: i % 50, y: Math.floor(i / 50) });
      }
      const samples: number[] = [];
      for (let frame = 0; frame < frames; frame += 1) {
        const start = performance.now();
        const zoom = 1 + (frame % 5) * 0.05;
        const dx = frame % 7;
        const dy = frame % 11;
        for (let i = 0; i < positions.length; i += 1) {
          const point = positions[i];
          point.x = (point.x + dx) * zoom;
          point.y = (point.y + dy) * zoom;
        }
        samples.push(performance.now() - start);
      }
      const sorted = [...samples].sort((a, b) => a - b);
      const idx = Math.min(sorted.length - 1, Math.floor(sorted.length * 0.95));
      return {
        p95_ms: sorted[idx],
        samples_ms: samples
      };
    },
    defaultFlowSnapshot
  };
}
