# Backup/restore SQLite

Текущий статус:
- документ описывает действующий baseline backup/restore для `stage11`;
- helper, smoke и live runtime-артефакты для SQLite уже есть;
- remaining blocker `stage11` относится уже не к backup/restore и не к live `kill -9` chaos, а к отдельному `storage pressure / disk exhaustion` contour.

- Частота backup: каждые 15 минут.
- Частота backup enforced в живом `art-core`: новый backup не создаётся чаще этого окна.
- Исключения, когда backup создаётся принудительно:
  - старт нового экземпляра `Core`;
  - успешная смена `effective_profile_id`.
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
