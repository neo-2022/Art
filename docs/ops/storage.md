# Storage chaos (целевой контур)

Текущий статус:
- chaos helper-сценарии для SQLite уже существуют и проходят;
- этот документ фиксирует обязательный hostile-path для полного `stage11`;
- живой `kill -9` сценарий вокруг настоящего `art-core` теперь подтверждён отдельным runtime smoke и evidence;
- hostile storage-pressure runtime smoke теперь тоже подтверждён отдельным live contour и evidence;
- concurrency baseline для storage теперь тоже подтверждён stage-level evidence:
  - `8 writer`;
  - `4 reader`;
  - `10000 ops`;
  - явный JSON-лог с длительностью и инвариантами;
- фактический `disk full` hostile proof и archive/prune discipline уже materialized в live runtime smoke;
- storage-basement `stage11` теперь закрыт полностью, включая production-proof для `VACUUM/systemd`.
- downstream continuation durable storage/recovery остаётся уже в `stage23` и `stage37`.

Сценарии:
- kill -9 во время ingest
- disk full
- WAL corruption

Критерии pass/fail:
- recovery успешен
- ingest возвращается в норму
- события `observability_gap.*` фиксируются

## Repro шаги

### 1) kill -9 во время ingest
1. Запустить ingest нагрузку.
2. Выполнить `kill -9 <pid_art_core>`.
3. Перезапустить Core.
4. Выполнить `integrity check`.
5. Проверить, что ingest снова принимает события.
6. Проверить, что хотя бы часть принятых до `kill -9` событий сохранилась в snapshot после рестарта.

Доказательство в репозитории:
- `scripts/tests/storage_kill9_runtime.sh`
- `docs/governance/evidence/stage11_kill9_runtime.log`

### 2) disk full
1. Заполнить storage путь до 0 свободных байт.
2. Проверить, что ingest отвечает `HTTP 503` + `retry_after_ms`.
3. Проверить событие `observability_gap.storage_disk_full` в snapshot/stream.
4. Проверить, что housekeeping включает archive/prune и пишет `observability_gap.storage_archive_prune_activated`.
5. Освободить место и проверить восстановление ingest.

### 2A) storage pressure до `disk full`
1. Заполнить storage путь не до нуля, а до раннего `high watermark`.
2. Проверить, что:
   - `health` показывает `storage_pressure_state=high`;
   - тяжёлые write-path получают `503 + retry_after_ms`;
   - лёгкие write-path ещё проходят;
   - в snapshot есть `observability_gap.storage_pressure_high`.
3. Затем довести систему до `critical watermark`.
4. Проверить, что:
   - `health` показывает `storage_pressure_state=critical`;
   - даже обычные write-path получают `503 + retry_after_ms`;
   - в snapshot появляется `observability_gap.storage_pressure_high` с `pressure_state=critical`.
5. Освободить место и подтвердить возврат в `normal` без ручной правки БД.

Доказательство в репозитории:
- `scripts/tests/storage_pressure_runtime.sh`
- `docs/governance/evidence/stage11_storage_pressure_runtime.log`

### 3) WAL corruption
1. Включить WAL и создать запись, чтобы появился `*.sqlite3-wal`.
2. Повредить WAL байтами (`dd`/прямой overwrite файла).
3. Проверить, что выполняется алгоритм recovery:
   - `HTTP 503` + `retry_after_ms`
   - `observability_gap.storage_corrupted`
   - restore из backup
   - `integrity check`
   - при fail -> `read_only` + `observability_gap.storage_read_only`
