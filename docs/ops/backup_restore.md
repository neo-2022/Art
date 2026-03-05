# Backup/restore SQLite

- backup: `sqlite3 data/core.db ".backup data/core.db.bak"`
- WAL учитывается через backup API sqlite3.
- integrity: `sqlite3 data/core.db "PRAGMA integrity_check;"`

pass/fail: pass
