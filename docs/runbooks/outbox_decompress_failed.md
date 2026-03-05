# Runbook: outbox_decompress_failed

## mitigations
1. Проверить целостность outbox payload (битые gzip записи).
2. Проверить версию кодека и совместимость формата хранения.
3. Перевести проблемные записи в DLQ/карантин и повторить flush.
4. Проверить транспорт до ingest после восстановления.

## verification
1. В snapshot/stream появилось событие `observability_gap.outbox_decompress_failed`.
2. В событии есть `trace_id` и evidence: `dedup_key`, `error`, `endpoint`.
3. После исправления новые события ошибки распаковки не появляются.
