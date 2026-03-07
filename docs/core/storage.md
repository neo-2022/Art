# Core storage target (SQLite, корректирующий stage11)

## Текущее состояние

- В этом репозитории уже есть:
  - helper-контур SQLite backup/restore/chaos;
  - рабочий `systemd`-контур для safe VACUUM;
  - smoke/e2e proof для `art-vacuum.service` и `art-vacuum.timer`.
- Живой `art-core` runtime теперь уже частично переведён на устойчивое SQLite-основание:
  - потоки событий `v1` и `v2` записываются в SQLite и поднимаются обратно после рестарта;
  - `incidents` и `audit chain` тоже поднимаются обратно после рестарта;
  - `fingerprint_index` и `source_last_seen` теперь тоже сохраняются и восстанавливаются из SQLite;
  - `DNA-derived state` (`dna_clusters`) и `evidence_blocks` сохраняются и поднимаются обратно после рестарта;
  - `analytics` и `counters` теперь сохраняются в SQLite как primary recovery state, а `CORE_ANALYTICS_STATE_PATH` остаётся только legacy mirror/import path;
  - `WAL` и `busy_timeout` для SQLite basement включаются при старте;
  - backup-каталог теперь вычисляется не только по профилю, но и по конкретному пути к БД, чтобы разные экземпляры `Core` не делили один backup-root;
  - restart-proof для `v1/v2`, `incidents`, `audit chain`, `fingerprint/source indexes`, `dna/evidence` и аналитики зафиксирован в evidence `stage11_core_sqlite_restart.log`.
  - hostile backup/restore proof для полного состояния `art-core` после corruption теперь тоже зафиксирован в evidence `stage11_core_sqlite_hostile_recovery.log`.
- При этом storage contour `stage11` всё ещё не доведён до полного production-состояния:
  - live corruption/read-only contour уже материализован end-to-end:
    - corruption на ingest даёт `HTTP 503 + retry_after_ms`;
    - `observability_gap.storage_corrupted` попадает в snapshot/stream;
    - при наличии валидного backup выполняется restore и следующий retry проходит;
    - при отсутствии валидного backup Core уходит в `read_only` и фиксирует `observability_gap.storage_read_only`;
  - backup cadence больше не привязан к каждой записи: живой `Core` держит фиксированное окно `15 минут`, а force-refresh допускается только на startup/profile-switch;
  - backup/restore/systemd path уже доказан по hostile proof и smoke;
  - оставшийся blocker `stage11` уже уже не в corruption/read_only contour, а в том, что сценарий `kill -9 Core во время живого ingest` всё ещё подтверждён только helper/smoke-путём, а не полноценным live-process chaos вокруг настоящего `art-core`.

## Целевой storage-контур `stage11`

- SQLite должен работать в режиме WAL.
- При детекте corruption:
  - ingest возвращает `HTTP 503` и `retry_after_ms`;
  - генерируется `observability_gap.storage_corrupted`;
  - выполняется restore из последнего валидного backup;
  - после restore выполняется `integrity check`.
- При провале restore:
  - Core переходит в `read_only`;
  - ingest продолжает `HTTP 503` и `retry_after_ms`;
  - генерируется `observability_gap.storage_read_only`.
- Обязательные события storage:
  - `observability_gap.storage_corrupted`
  - `observability_gap.storage_read_only`
  - `observability_gap.storage_vacuum_failed`
  - `observability_gap.storage_disk_full`
- Плановый VACUUM:
  - выполняется через `systemd/art-vacuum.service` + `systemd/art-vacuum.timer`;
  - unit обязан проходить `systemd-analyze verify`;
  - при ошибке unit пишет структурированное событие `observability_gap.storage_vacuum_failed` в `journal/stderr`.
