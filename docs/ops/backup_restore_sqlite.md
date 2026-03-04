# Backup/restore SQLite

- Частота backup: каждые 15 минут.
- Храним минимум N=96 последних backup.
- Путь хранения задаётся профилем (`effective_profile_id`).
- Backup включает DB + WAL + метаданные.
- После restore обязателен integrity check.
