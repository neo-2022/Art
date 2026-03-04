# Ingest chaos

Сценарии:
- kill -9 Core во время ingest
- disk full
- recovery после освобождения места

Проверки:
- `ack.upto_seq` остаётся монотонным
- 503 + retry_after_ms при отказе
- события `observability_gap.ingest_unavailable`/`observability_gap.storage_disk_full`
