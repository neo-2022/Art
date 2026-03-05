# Backup/restore SQLite

- Частота backup: каждые 15 минут.
- Храним минимум N=96 последних backup.
- Путь хранения задаётся профилем (`effective_profile_id`).
- Базовый путь:
  - `default`: `/var/lib/art/backups/default/`
  - `eu`: `/var/lib/art/backups/eu/`
  - `ru`: `/var/lib/art/backups/ru/`
  - `airgapped`: `/var/lib/art/backups/airgapped/`
- Backup включает DB + WAL + метаданные.
- После restore обязателен `integrity check`.
