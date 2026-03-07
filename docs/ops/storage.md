# Storage chaos (целевой контур)

Текущий статус:
- chaos helper-сценарии для SQLite уже существуют и проходят;
- этот документ фиксирует обязательный hostile-path для полного `stage11`;
- пока живой `art-core` ещё не использует SQLite как полный durable basement, сценарии остаются corrective target для runtime.

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
