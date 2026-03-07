# Storage chaos (целевой контур)

Текущий статус:
- chaos helper-сценарии для SQLite уже существуют и проходят;
- этот документ фиксирует обязательный hostile-path для полного `stage11`;
- живой `kill -9` сценарий вокруг настоящего `art-core` теперь подтверждён отдельным runtime smoke и evidence;
- открытым corrective-блокером `stage11` остаётся не `kill -9`, а `storage pressure / disk exhaustion` contour.

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
4. Освободить место и проверить восстановление ingest.

### 3) WAL corruption
1. Включить WAL и создать запись, чтобы появился `*.sqlite3-wal`.
2. Повредить WAL байтами (`dd`/прямой overwrite файла).
3. Проверить, что выполняется алгоритм recovery:
   - `HTTP 503` + `retry_after_ms`
   - `observability_gap.storage_corrupted`
   - restore из backup
   - `integrity check`
   - при fail -> `read_only` + `observability_gap.storage_read_only`
