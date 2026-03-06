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

export function createLocalStores() {
  const cache = new Map<string, CachedEvent>();
  const analyticsCounters = new Map<string, number>();
  const timeline = new Map<number, { total_events: number; gap_events: number }>();
  const severityCounters = new Map<string, number>();
  const kindCounters = new Map<string, number>();
  const dnaCounters = new Map<string, number>();
  let totalEvents = 0;
  let gapEvents = 0;

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
    spatialStoreStub() {
      return {
        status: "stubbed",
        model: "typed-array-contract"
      } as const;
    }
  };
}
