# Outbox limits

Политики:
- never_drop_unacked
- drop_oldest_when_full

Лимиты:
- max_age: 7 суток
- dlq_retention: 30 суток
- dedup_ttl_ms: 300000
- cleanup_interval_ms: 300000
- max_pending: 1000 (по умолчанию)

События при overflow:
- never_drop_unacked -> `observability_gap.outbox_full`
- drop_oldest_when_full -> `data_quality.lossy_outbox_drop` + `incident.lossy_mode_active`
