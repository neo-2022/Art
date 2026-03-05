# Metrics

Endpoint: `/metrics`

Ключевые метрики:
- `ingest_latency_ms`
- `stream_lag_ms`
- `spool_used_bytes`
- `dlq_size`

При недоступности endpoint генерируется `observability_gap.metrics_unavailable`.
