# DB migration runbook

1. backup SQLite (`.backup`).
2. остановка core.
3. запуск миграций.
4. `PRAGMA integrity_check;` (integrity).
5. smoke health/snapshot.
6. rollback при fail.
