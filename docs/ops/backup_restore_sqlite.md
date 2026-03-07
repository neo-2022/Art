# Backup/restore SQLite (целевой контур)

Текущий статус:
- документ описывает целевой baseline backup/restore для корректирующего `stage11`;
- helper и smoke-артефакты для SQLite уже есть;
- полный перевод живого `art-core` на этот backup/restore contour ещё не завершён.

- Частота backup: каждые 15 минут.
- Храним минимум N=96 последних backup.
- Путь хранения задаётся профилем (`effective_profile_id`) и конкретным экземпляром БД.
- Это сделано специально, чтобы два `Core` с одним и тем же профилем не писали backup в один каталог и не повреждали контур восстановления друг друга.
- Базовый путь:
  - `default`: `/var/lib/art/backups/default/<db_scope_id>/`
  - `eu`: `/var/lib/art/backups/eu/<db_scope_id>/`
  - `ru`: `/var/lib/art/backups/ru/<db_scope_id>/`
  - `airgapped`: `/var/lib/art/backups/airgapped/<db_scope_id>/`
- `db_scope_id` вычисляется детерминированно из пути к SQLite-файлу и делает backup-каталог уникальным для каждого экземпляра `Core`.
- Backup включает DB + WAL + метаданные.
- После restore обязателен `integrity check`.
