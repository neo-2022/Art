# Runbook: outbox_full

## mitigations
1. Проверить текущий `max_pending` и backlog outbox.
2. Восстановить доставку в ingest (сеть, endpoint, ошибки 5xx/timeout).
3. Для `never_drop_unacked` временно уменьшить поток входящих событий.
4. При необходимости масштабировать ingest/flush path.

## verification
1. В snapshot/stream есть `observability_gap.outbox_full` c `limit/pending_count/trace_id`.
2. Счётчик `outbox_rejected_total` стабилизировался после восстановления.
3. Новые enqueue проходят без reject.
