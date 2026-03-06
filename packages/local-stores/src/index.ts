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

export interface Vec3 {
  x: number;
  y: number;
  z: number;
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
  proof_refs?: string[];
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

export interface InvestigationCompareResult {
  same_signature: boolean;
  deltas: {
    claims: number;
    decisions: number;
    actions: number;
    results: number;
    evidence_refs: number;
    audit_refs: number;
  };
}

export interface LrcRunbookStep {
  step_id: string;
  title: string;
  requires_evidence_refs: string[];
}

export interface LrcRunbook {
  runbook_id: string;
  steps: LrcRunbookStep[];
}

export interface LrcConditionNode {
  step_id: string;
  title: string;
  missing_evidence_refs: string[];
  status: "valid" | "invalid";
}

export interface LrcCompileResult {
  runbook_id: string;
  graph: LrcConditionNode[];
  invalid_steps: string[];
}

const INVESTIGATION_REQUIRED_FIELDS = [
  "doc_id",
  "version",
  "claims",
  "decisions",
  "actions",
  "results",
  "evidence_refs",
  "audit_refs"
] as const;

const FLOW_TYPES: FlowSemanticType[] = [
  "dna_cloud",
  "incident_cloud",
  "gap_cloud",
  "service_node",
  "store_node",
  "buffer_node",
  "agent_node"
];

const SENSITIVE_KEY_PATTERN = /(password|secret|token|api[_-]?key|authorization|cookie|set-cookie|passwd)/i;
const REDACTED_VALUE = "[REDACTED]";

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

function sanitizePayload(input: unknown): unknown {
  if (input === null || input === undefined) {
    return input ?? null;
  }
  if (Array.isArray(input)) {
    return input.map((item) => sanitizePayload(item));
  }
  if (typeof input !== "object") {
    return input;
  }
  const source = input as Record<string, unknown>;
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(source)) {
    if (SENSITIVE_KEY_PATTERN.test(key)) {
      out[key] = REDACTED_VALUE;
      continue;
    }
    out[key] = sanitizePayload(value);
  }
  return out;
}

function simpleHash(input: string): string {
  let hash = 2166136261;
  for (let i = 0; i < input.length; i += 1) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return `h${(hash >>> 0).toString(16).padStart(8, "0")}`;
}

function assertInvestigationDocShape(input: unknown): asserts input is InvestigationDoc {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("investigation_doc_invalid_shape");
  }
  const doc = input as Record<string, unknown>;
  for (const field of INVESTIGATION_REQUIRED_FIELDS) {
    if (!(field in doc)) {
      throw new Error(`investigation_doc_missing_field:${field}`);
    }
  }
  if (typeof doc.doc_id !== "string" || doc.doc_id.length === 0) {
    throw new Error("investigation_doc_invalid_doc_id");
  }
  if (typeof doc.version !== "string" || doc.version.length === 0) {
    throw new Error("investigation_doc_invalid_version");
  }
  for (const field of ["claims", "decisions", "actions", "results", "evidence_refs", "audit_refs"] as const) {
    if (!Array.isArray(doc[field])) {
      throw new Error(`investigation_doc_invalid_field_type:${field}`);
    }
  }
  if (doc.proof_refs !== undefined && !Array.isArray(doc.proof_refs)) {
    throw new Error("investigation_doc_invalid_field_type:proof_refs");
  }
}

export function serializeInvestigationDoc(doc: InvestigationDoc): string {
  assertInvestigationDocShape(doc);
  return stableStringify(doc);
}

export function parseInvestigationDoc(serialized: string): InvestigationDoc {
  const parsed = JSON.parse(serialized) as unknown;
  assertInvestigationDocShape(parsed);
  return parsed;
}

function canonicalSignaturePayload(doc: InvestigationDoc): InvestigationDoc {
  const cloned = JSON.parse(serializeInvestigationDoc(doc)) as InvestigationDoc;
  delete (cloned as { signature?: string }).signature;
  return cloned;
}

export function compileLiveRunbook(runbook: LrcRunbook, availableEvidenceRefs: string[]): LrcCompileResult {
  const evidenceSet = new Set(availableEvidenceRefs);
  const graph: LrcConditionNode[] = runbook.steps.map((step) => {
    const missing = step.requires_evidence_refs.filter((ref) => !evidenceSet.has(ref));
    return {
      step_id: step.step_id,
      title: step.title,
      missing_evidence_refs: missing,
      status: missing.length === 0 ? "valid" : "invalid"
    };
  });
  return {
    runbook_id: runbook.runbook_id,
    graph,
    invalid_steps: graph.filter((node) => node.status === "invalid").map((node) => node.step_id)
  };
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

function encodeSpatialChunk(layoutId: string, entries: Array<{ node_id: string; x: number; y: number; z: number }>): Uint8Array {
  const metadataJson = JSON.stringify({
    version: "v0.2",
    layout_id: layoutId,
    count: entries.length
  });
  const metadataBytes = new TextEncoder().encode(metadataJson);
  const payload = new Uint8Array(entries.length * 12);
  const payloadView = new DataView(payload.buffer);
  const nodeIds = entries.map((entry) => entry.node_id);

  entries.forEach((entry, idx) => {
    const base = idx * 12;
    payloadView.setFloat32(base, entry.x, true);
    payloadView.setFloat32(base + 4, entry.y, true);
    payloadView.setFloat32(base + 8, entry.z, true);
  });

  const idsJson = JSON.stringify(nodeIds);
  const idsBytes = new TextEncoder().encode(idsJson);
  const out = new Uint8Array(4 + metadataBytes.length + 4 + idsBytes.length + payload.length);
  const view = new DataView(out.buffer);
  let offset = 0;
  view.setUint32(offset, metadataBytes.length, true);
  offset += 4;
  out.set(metadataBytes, offset);
  offset += metadataBytes.length;
  view.setUint32(offset, idsBytes.length, true);
  offset += 4;
  out.set(idsBytes, offset);
  offset += idsBytes.length;
  out.set(payload, offset);
  return out;
}

function decodeSpatialChunk(chunk: Uint8Array): {
  layout_id: string;
  entries: Array<{ node_id: string; x: number; y: number; z: number }>;
} {
  const view = new DataView(chunk.buffer, chunk.byteOffset, chunk.byteLength);
  if (chunk.byteLength < 8) {
    throw new Error("spatial_chunk_too_small");
  }
  let offset = 0;
  const metadataLen = view.getUint32(offset, true);
  offset += 4;
  if (offset + metadataLen > chunk.byteLength) {
    throw new Error("spatial_chunk_bad_metadata_length");
  }
  const metadataJson = new TextDecoder().decode(chunk.slice(offset, offset + metadataLen));
  offset += metadataLen;
  const metadata = JSON.parse(metadataJson) as { layout_id?: string; count?: number };
  if (!metadata.layout_id) {
    throw new Error("spatial_chunk_missing_layout_id");
  }
  const count = Number(metadata.count || 0);

  if (offset + 4 > chunk.byteLength) {
    throw new Error("spatial_chunk_missing_ids_length");
  }
  const idsLen = view.getUint32(offset, true);
  offset += 4;
  if (offset + idsLen > chunk.byteLength) {
    throw new Error("spatial_chunk_bad_ids_length");
  }
  const idsJson = new TextDecoder().decode(chunk.slice(offset, offset + idsLen));
  offset += idsLen;
  const nodeIds = JSON.parse(idsJson) as string[];
  if (!Array.isArray(nodeIds) || nodeIds.length !== count) {
    throw new Error("spatial_chunk_ids_count_mismatch");
  }

  const remaining = chunk.byteLength - offset;
  if (remaining !== count * 12) {
    throw new Error("spatial_chunk_payload_length_mismatch");
  }
  const payload = new DataView(chunk.buffer, chunk.byteOffset + offset, remaining);
  const entries: Array<{ node_id: string; x: number; y: number; z: number }> = [];
  for (let idx = 0; idx < count; idx += 1) {
    const base = idx * 12;
    entries.push({
      node_id: nodeIds[idx],
      x: payload.getFloat32(base, true),
      y: payload.getFloat32(base + 4, true),
      z: payload.getFloat32(base + 8, true)
    });
  }
  return { layout_id: metadata.layout_id, entries };
}

export function createLocalStores() {
  const cache = new Map<string, CachedEvent>();
  const analyticsCounters = new Map<string, number>();
  const timeline = new Map<number, { total_events: number; gap_events: number }>();
  const severityCounters = new Map<string, number>();
  const kindCounters = new Map<string, number>();
  const dnaCounters = new Map<string, number>();
  const layoutStore = new Map<string, Map<string, Vec2>>();
  const spatialGridIndexStore = new Map<
    string,
    {
      cell_size: number;
      cells: Map<string, string[]>;
    }
  >();
  const snapshots = new Map<string, FlowSnapshotState>();
  const investigationStore = new Map<string, InvestigationDoc>();
  const investigationMeta = new Map<string, InvestigationLibraryItem>();
  let selection2d: string[] = [];
  let selection3d: string[] = [];
  let flowComplexity: FlowComplexity = "advanced";
  let totalEvents = 0;
  let gapEvents = 0;
  let soaCapacity = 256;
  let soaCount = 0;
  let soaX = new Float32Array(soaCapacity);
  let soaY = new Float32Array(soaCapacity);
  let soaZ = new Float32Array(soaCapacity);
  const soaIndexByNodeId = new Map<string, number>();
  const soaNodeIdByIndex: string[] = new Array(soaCapacity);

  function ensureLayout(layoutId: string): Map<string, Vec2> {
    const existing = layoutStore.get(layoutId);
    if (existing) {
      return existing;
    }
    const created = new Map<string, Vec2>();
    layoutStore.set(layoutId, created);
    return created;
  }

  function gridKey(x: number, y: number, cellSize: number): string {
    const gx = Math.floor(x / cellSize);
    const gy = Math.floor(y / cellSize);
    return `${gx}:${gy}`;
  }

  function ensureSoaCapacity(nextCount: number): void {
    if (nextCount <= soaCapacity) {
      return;
    }
    let nextCapacity = soaCapacity;
    while (nextCapacity < nextCount) {
      nextCapacity *= 2;
    }
    const nx = new Float32Array(nextCapacity);
    const ny = new Float32Array(nextCapacity);
    const nz = new Float32Array(nextCapacity);
    nx.set(soaX.subarray(0, soaCount));
    ny.set(soaY.subarray(0, soaCount));
    nz.set(soaZ.subarray(0, soaCount));
    soaX = nx;
    soaY = ny;
    soaZ = nz;
    soaNodeIdByIndex.length = nextCapacity;
    soaCapacity = nextCapacity;
  }

  function upsertSoaNode(nodeId: string, vec: Vec3): void {
    let idx = soaIndexByNodeId.get(nodeId);
    if (idx === undefined) {
      ensureSoaCapacity(soaCount + 1);
      idx = soaCount;
      soaCount += 1;
      soaIndexByNodeId.set(nodeId, idx);
      soaNodeIdByIndex[idx] = nodeId;
    }
    soaX[idx] = vec.x;
    soaY[idx] = vec.y;
    soaZ[idx] = vec.z;
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
    const canonical = serializeInvestigationDoc(canonicalSignaturePayload(input));
    const signature = input.signature || simpleHash(canonical);
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
      const sanitizedPayload = sanitizePayload(event.payload) as Record<string, unknown>;
      const sanitizedEvent: CachedEvent = {
        id: event.id,
        dna_id: event.dna_id,
        payload: sanitizedPayload
      };
      cache.set(event.id, sanitizedEvent);
      analyticsCounters.set(event.dna_id, (analyticsCounters.get(event.dna_id) || 0) + 1);
      recordTelemetry({
        ts_ms: Date.now(),
        severity: String(sanitizedPayload["severity"] || "unknown"),
        kind: String(sanitizedPayload["kind"] || "unknown"),
        dna_id: event.dna_id,
        is_gap: String(sanitizedPayload["kind"] || "").startsWith("observability_gap.")
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
      upsertSoaNode(nodeId, { x: vec.x, y: vec.y, z: 0 });
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
    spatialUpsertNode(nodeId: string, vec: Vec3): void {
      upsertSoaNode(nodeId, vec);
    },
    spatialGetNode(nodeId: string): Vec3 | null {
      const idx = soaIndexByNodeId.get(nodeId);
      if (idx === undefined) {
        return null;
      }
      return { x: soaX[idx], y: soaY[idx], z: soaZ[idx] };
    },
    spatialNodeCount(): number {
      return soaCount;
    },
    spatialPersistBinaryChunk(layoutId = "default"): Uint8Array {
      const layout = ensureLayout(layoutId);
      const entries = [...layout.entries()].map(([nodeId, vec]) => ({
        node_id: nodeId,
        x: vec.x,
        y: vec.y,
        z: 0
      }));
      return encodeSpatialChunk(layoutId, entries);
    },
    spatialLoadBinaryChunk(chunk: Uint8Array): { layout_id: string; restored: number } {
      const decoded = decodeSpatialChunk(chunk);
      const layout = ensureLayout(decoded.layout_id);
      layout.clear();
      decoded.entries.forEach((entry) => {
        layout.set(entry.node_id, { x: entry.x, y: entry.y });
        upsertSoaNode(entry.node_id, { x: entry.x, y: entry.y, z: entry.z });
      });
      return { layout_id: decoded.layout_id, restored: decoded.entries.length };
    },
    spatialBuildGridIndex(layoutId = "default", cellSize = 32): {
      layout_id: string;
      cell_size: number;
      cells: number;
      indexed_nodes: number;
    } {
      const layout = ensureLayout(layoutId);
      const cells = new Map<string, string[]>();
      for (const [nodeId, vec] of layout.entries()) {
        const key = gridKey(vec.x, vec.y, cellSize);
        const bucket = cells.get(key) || [];
        bucket.push(nodeId);
        cells.set(key, bucket);
      }
      spatialGridIndexStore.set(layoutId, { cell_size: cellSize, cells });
      return {
        layout_id: layoutId,
        cell_size: cellSize,
        cells: cells.size,
        indexed_nodes: layout.size
      };
    },
    spatialPick(layoutId: string, x: number, y: number, radius = 48): {
      node_id: string | null;
      examined_nodes: number;
      candidate_nodes: number;
      used_full_scan: boolean;
    } {
      const layout = ensureLayout(layoutId);
      const index = spatialGridIndexStore.get(layoutId);
      let candidates: string[] = [];
      let usedFullScan = false;

      if (index) {
        const gx = Math.floor(x / index.cell_size);
        const gy = Math.floor(y / index.cell_size);
        for (let dy = -1; dy <= 1; dy += 1) {
          for (let dx = -1; dx <= 1; dx += 1) {
            const key = `${gx + dx}:${gy + dy}`;
            const bucket = index.cells.get(key);
            if (bucket && bucket.length > 0) {
              candidates = candidates.concat(bucket);
            }
          }
        }
      }

      if (candidates.length === 0) {
        return {
          node_id: null,
          examined_nodes: 0,
          candidate_nodes: 0,
          used_full_scan: false
        };
      }

      let bestNode: string | null = null;
      let bestDist = Number.POSITIVE_INFINITY;
      let examined = 0;
      for (const nodeId of candidates) {
        const vec = layout.get(nodeId);
        if (!vec) {
          continue;
        }
        examined += 1;
        const dx = vec.x - x;
        const dy = vec.y - y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist <= radius && dist < bestDist) {
          bestDist = dist;
          bestNode = nodeId;
        }
      }
      return {
        node_id: bestNode,
        examined_nodes: examined,
        candidate_nodes: candidates.length,
        used_full_scan: usedFullScan
      };
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
    profileGpuCapability(input: {
      renderer: string;
      is_vm?: boolean;
      vram_mb?: number;
    }): {
      gpu_class: "weak" | "standard" | "strong";
      fallback_profile: "read-only" | "advanced";
      reason: string;
    } {
      const renderer = (input.renderer || "").toLowerCase();
      const isWeakRenderer =
        renderer.includes("uhd 620") ||
        renderer.includes("intel uhd") ||
        renderer.includes("llvmpipe") ||
        renderer.includes("virtio") ||
        renderer.includes("vmware");
      const lowVram = typeof input.vram_mb === "number" && input.vram_mb > 0 && input.vram_mb < 1024;
      if (isWeakRenderer || lowVram || input.is_vm) {
        return {
          gpu_class: "weak",
          fallback_profile: "read-only",
          reason: "weak_gpu_or_vm_profile"
        };
      }
      if (typeof input.vram_mb === "number" && input.vram_mb >= 4096) {
        return {
          gpu_class: "strong",
          fallback_profile: "advanced",
          reason: "high_vram_profile"
        };
      }
      return {
        gpu_class: "standard",
        fallback_profile: "advanced",
        reason: "standard_profile"
      };
    },
    syncSelection2dTo3d(nodeIds: string[]): { selection_2d: string[]; selection_3d: string[] } {
      const normalized = [...new Set(nodeIds.filter(Boolean))].sort();
      selection2d = normalized;
      selection3d = [...normalized];
      return { selection_2d: [...selection2d], selection_3d: [...selection3d] };
    },
    syncSelection3dTo2d(nodeIds: string[]): { selection_2d: string[]; selection_3d: string[] } {
      const normalized = [...new Set(nodeIds.filter(Boolean))].sort();
      selection3d = normalized;
      selection2d = [...normalized];
      return { selection_2d: [...selection2d], selection_3d: [...selection3d] };
    },
    currentSelectionSyncState(): { selection_2d: string[]; selection_3d: string[] } {
      return { selection_2d: [...selection2d], selection_3d: [...selection3d] };
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
      const expected = simpleHash(serializeInvestigationDoc(canonicalSignaturePayload(doc)));
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
        `audit_refs:${doc.audit_refs.length}`,
        `proof_refs:${Array.isArray(doc.proof_refs) ? doc.proof_refs.length : 0}`
      ];
      return { ok: true, steps };
    },
    forkInvestigationDoc(docId: string, forkDocId: string): InvestigationLibraryItem | null {
      const source = investigationStore.get(docId);
      if (!source || !forkDocId) {
        return null;
      }
      const forkDoc: InvestigationDoc = {
        ...JSON.parse(serializeInvestigationDoc(source)) as InvestigationDoc,
        doc_id: forkDocId,
        version: `${source.version}-fork`,
        signature: undefined
      };
      return importInvestigationDoc(forkDoc);
    },
    compareInvestigationDocs(leftDocId: string, rightDocId: string): InvestigationCompareResult | null {
      const left = investigationStore.get(leftDocId);
      const right = investigationStore.get(rightDocId);
      if (!left || !right) {
        return null;
      }
      return {
        same_signature: (left.signature || "") === (right.signature || ""),
        deltas: {
          claims: left.claims.length - right.claims.length,
          decisions: left.decisions.length - right.decisions.length,
          actions: left.actions.length - right.actions.length,
          results: left.results.length - right.results.length,
          evidence_refs: left.evidence_refs.length - right.evidence_refs.length,
          audit_refs: left.audit_refs.length - right.audit_refs.length
        }
      };
    },
    traceEvidenceLineagePath(input: {
      event_id: string;
      evidence_id: string;
      claim_id: string;
      investigation_id: string;
      evidence_lineage_id: string;
    }): { ok: boolean; path: string[] } {
      if (
        !input.event_id ||
        !input.evidence_id ||
        !input.claim_id ||
        !input.investigation_id ||
        !input.evidence_lineage_id
      ) {
        return { ok: false, path: [] };
      }
      return {
        ok: true,
        path: [
          `event:${input.event_id}`,
          `evidence:${input.evidence_id}`,
          `claim:${input.claim_id}`,
          `investigation:${input.investigation_id}`,
          `lineage:${input.evidence_lineage_id}`
        ]
      };
    },
    spatialStoreStub() {
      return {
        status: "stubbed",
        model: "typed-array-contract",
        interface: [
          "setPosition",
          "getLayout",
          "saveSnapshot",
          "loadSnapshot",
          "listSnapshots",
          "spatialUpsertNode",
          "spatialGetNode",
          "spatialPersistBinaryChunk",
          "spatialLoadBinaryChunk"
        ]
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
