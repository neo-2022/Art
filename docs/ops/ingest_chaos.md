# Ingest chaos

Сценарии:
- kill -9 Core во время ingest
- disk full
- recovery после освобождения места

Проверки:
- `ack.upto_seq` остаётся монотонным
- 503 + retry_after_ms при отказе
- события `observability_gap.ingest_unavailable`/`observability_gap.storage_disk_full`

## Repro шаги

### 1) kill -9 во время ingest
1. Запустить непрерывный ingest поток.
2. Выполнить `kill -9 <pid_art_core>`.
3. Перезапустить Core.
4. Отправить новый batch и проверить `HTTP 200`.
5. Проверить, что `ack.upto_seq` после рестарта > предыдущего успешного значения.

### 2) disk full
1. Заполнить storage путь до отсутствия свободного места.
2. Проверить ответ ingest: `HTTP 503` + `retry_after_ms`.
3. Проверить событие `observability_gap.ingest_unavailable` или `observability_gap.storage_disk_full`.
4. Освободить место.

### 3) recovery
1. Повторить ingest после освобождения места.
2. Проверить возврат в нормальный режим (`HTTP 200`).
3. Проверить отсутствие ручной правки данных в SQLite/WAL.
