# Alerts

Алерты и пороги:
- p95 ingest latency > 500ms (окно 5m) -> `core.high_latency`
- spool usage ratio >= 0.90 (окно 1m) -> `agent.spool_near_full`
- dlq_size > 0 (окно 10m) -> `dlq_non_empty`
- source_stale threshold 600000ms -> `source_stale`
