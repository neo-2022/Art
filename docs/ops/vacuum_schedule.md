# VACUUM schedule

Текущий статус:
- `systemd/art-vacuum.service` и `systemd/art-vacuum.timer` уже приведены к рабочему состоянию;
- safe skip при активном ingest и structured gap event при ошибке подтверждены smoke-тестом;
- полный эффект для всего storage-основания `art-core` остаётся частью корректирующего `stage11`, пока сам Core не живёт на устойчивом SQLite-основании.

- Расписание: воскресенье (Sunday) 03:30.
- Используются `systemd/art-vacuum.service` и `systemd/art-vacuum.timer`.
- VACUUM выполняется в safe-режиме (без активного ingest).
- Успешный запуск пишет в journal строку `vacuum_status=ok ...`.
- Если ingest активен, запуск не ломает БД, а пишет `vacuum_status=skipped reason=ingest_active ...`.
- Ошибка VACUUM -> `observability_gap.storage_vacuum_failed` в виде структурированного JSON в `stderr/journal` с evidence:
  - `db_path`
  - `error`
  - `schedule`
  - `trace_id`
- Unit обязан проходить `systemd-analyze verify` без ошибок.
