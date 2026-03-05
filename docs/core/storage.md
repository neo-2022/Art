# Core storage (SQLite)

- SQLite работает в режиме WAL.
- При детекте corruption:
  - ingest возвращает `HTTP 503` и `retry_after_ms`.
  - генерируется `observability_gap.storage_corrupted`.
  - выполняется restore из последнего валидного backup.
  - после restore выполняется `integrity check`.
- При провале restore:
  - Core переходит в `read_only`.
  - ingest продолжает `HTTP 503` и `retry_after_ms`.
  - генерируется `observability_gap.storage_read_only`.
- Обязательные события storage:
  - `observability_gap.storage_corrupted`
  - `observability_gap.storage_read_only`
  - `observability_gap.storage_vacuum_failed`
  - `observability_gap.storage_disk_full`
