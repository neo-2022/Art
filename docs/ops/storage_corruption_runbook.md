# Runbook: storage_corruption

Текущий статус:
- алгоритм ниже уже реализован в живом `art-core`;
- helper recovery/chaos сценарии и live runtime tests подтверждают этот порядок;
- live-process chaos сценарий `kill -9` во время ingest теперь тоже доказан отдельно;
- оставшийся открытый contour `stage11` относится уже к `storage pressure / disk exhaustion`, а не к corruption/read_only или kill -9 recovery.

При corruption (строгий порядок):
1. ingest -> `HTTP 503`
2. ответ содержит `retry_after_ms` (>= 0)
3. генерируется `observability_gap.storage_corrupted` с evidence:
   - `db_path`
   - `corruption_type`
   - `sqlite_error`
   - `last_ok_backup_id` (`none`, если backup отсутствует)
   - `trace_id`
4. restore из последнего валидного backup
5. `integrity check` после restore
6. если restore неуспешен -> режим `read_only`
7. в `read_only` ingest остаётся на `HTTP 503` + `retry_after_ms`
8. генерируется `observability_gap.storage_read_only`
