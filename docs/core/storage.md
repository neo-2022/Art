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
- concurrency proof `11.3` теперь materialize отдельным runtime-evidence:
  - `8 writer` + `4 reader`;
  - `10000` операций как фиксированный closure-критерий;
  - отдельный JSON-лог фиксирует `writers/readers/ops_target/elapsed_seconds/accepted/committed/db_count`;
  - отсутствие `database is locked` как фатальной ошибки теперь доказывается не только unit-assertions, но и stage-level evidence `stage11_step3_concurrency.log`;
- backup-каталог теперь вычисляется не только по профилю, но и по конкретному пути к БД, чтобы разные экземпляры `Core` не делили один backup-root;
- restart-proof для `v1/v2`, `incidents`, `audit chain`, `fingerprint/source indexes`, `dna/evidence` и аналитики зафиксирован в evidence `stage11_core_sqlite_restart.log`.
- hostile backup/restore proof для полного состояния `art-core` после corruption теперь тоже зафиксирован в evidence `stage11_core_sqlite_hostile_recovery.log`.
- hostile storage-pressure proof теперь тоже materialize:
  - `high watermark` -> `observability_gap.storage_pressure_high` -> heavy write shed;
  - `critical watermark` -> более жёсткий `503 + retry_after_ms` на write-path;
  - фактический `disk full` -> `observability_gap.storage_disk_full`;
  - pressure housekeeping -> `observability_gap.storage_archive_prune_activated`;
  - после возврата свободного места `Core` возвращается в `normal` без ручной правки БД;
  - это подтверждено отдельным live runtime smoke и evidence `stage11_storage_pressure_runtime.log`.
- Storage contour `stage11` теперь доведён до полного production-baseline:
  - live corruption/read-only contour материализован end-to-end;
  - backup cadence `15 минут` enforced в runtime;
  - backup/restore/systemd path доказан hostile proof и отдельным runtime smoke;
  - live-process hostile contour `kill -9 Core во время живого ingest` доказан отдельным runtime smoke и evidence `stage11_kill9_runtime.log`;
  - concurrency proof `8 writer / 4 reader / 10000 ops` подтверждён отдельным stage-level evidence `stage11_step3_concurrency.log`;
  - production-proof для `VACUUM/systemd` подтверждён отдельным runtime smoke/evidence `stage11_step4_vacuum_runtime.log`.
- Downstream continuation durable storage/recovery остаётся уже не в `stage11`, а в `stage23` и `stage37`.

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
