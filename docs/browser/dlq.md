# Browser DLQ

- outbox TTL: 7 суток
- DLQ retention: 30 суток
- события истечения: `observability_gap.outbox_event_expired`
- события overflow-drop: `data_quality.lossy_outbox_drop`
- purge DLQ: hard delete после истечения retention
