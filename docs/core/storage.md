# Core storage (SQLite)

- SQLite WAL mode.
- Recovery policy при corruption: 503 + retry_after_ms + restore from backup.
- При провале restore: режим read_only.
- События: `observability_gap.storage_corrupted`, `observability_gap.storage_read_only`, `observability_gap.storage_disk_full`.
