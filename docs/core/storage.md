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
  - реальный `art-core` ещё не материализует end-to-end автоматический corruption detector, который сам переводит ingest в `HTTP 503 + retry_after_ms`, пишет `observability_gap.storage_corrupted`, делает restore и уходит в `read_only` при неуспехе;
  - backup/restore/systemd path уже доказан по hostile proof и smoke, но ещё не собран в единый self-healing runtime contour самого `Core`;
  - поэтому документ остаётся corrective-спецификацией и не утверждает, что весь runtime уже доведён до финальной цели.

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
