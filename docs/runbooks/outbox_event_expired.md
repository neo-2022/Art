# Runbook: outbox_event_expired

## mitigations
1. Проверить задержку доставки в ingest и backlog outbox.
2. Убедиться, что сеть/ingest доступен и flush работает.
3. Проверить лимиты TTL и cleanup scheduling.
4. Выгрузить события из DLQ для анализа потерь.

## verification
1. В snapshot/stream есть `observability_gap.outbox_event_expired`.
2. В evidence присутствуют: `dedup_key`, `age_ms`, `policy=ttl_7d`, `trace_id`.
3. После устранения причины новые TTL-expired события не растут.
