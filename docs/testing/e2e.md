# E2E стенд

## Базовый прогон (pass/fail)
1. Запустить Core и Agent.
2. Проверить `GET /api/v1/health` и `GET /api/v1/snapshot`.
3. Выполнить ingest тестовых событий и проверить `ack.upto_seq` монотонно растет.
4. Power loss сценарий: `kill -9 <core_pid>`, затем restart и проверка replay.

## Критерии
- pass: health/snapshot доступны, `ack.upto_seq` монотонен, дыры не обнаружены.
- fail: любой шаг не выполнен.
