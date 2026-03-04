# Runbook: storage_corruption

При corruption:
1. ingest -> HTTP 503
2. ответ содержит retry_after_ms
3. генерируется `observability_gap.storage_corrupted`
4. restore из последнего валидного backup
5. integrity check
6. если restore неуспешен -> read_only + `observability_gap.storage_read_only`
