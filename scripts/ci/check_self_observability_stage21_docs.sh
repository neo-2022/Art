#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/ops/self_observability.md \
  docs/ops/metrics.md \
  docs/ops/alerts.md \
  docs/runbooks/core_high_latency.md \
  docs/runbooks/agent_spool_near_full.md \
  docs/runbooks/dlq_non_empty.md \
  docs/runbooks/metrics_unavailable.md \
  grafana/art_core_overview.json \
  grafana/art_agent_overview.json \
  grafana/art_ingest_pipeline.json; do
  test -f "$f"
done

grep -q "core.high_latency" docs/ops/self_observability.md
grep -q "agent.spool_near_full" docs/ops/self_observability.md
grep -q "dlq_non_empty" docs/ops/self_observability.md
grep -q "source_stale" docs/ops/self_observability.md

grep -q "/metrics" docs/ops/metrics.md
grep -q "ingest_latency_ms" docs/ops/metrics.md
grep -q "stream_lag_ms" docs/ops/metrics.md
grep -q "spool_used_bytes" docs/ops/metrics.md
grep -q "dlq_size" docs/ops/metrics.md

grep -q "p95" docs/ops/alerts.md
grep -q "0.90" docs/ops/alerts.md
grep -q "500" docs/ops/alerts.md

grep -q "ingest" grafana/art_core_overview.json
