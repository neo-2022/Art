# VACUUM schedule

- Расписание: воскресенье (Sunday) 03:30.
- Используются `art-vacuum.service` и `art-vacuum.timer`.
- VACUUM выполняется в safe-режиме (без активного ingest).
- Ошибка VACUUM -> `observability_gap.storage_vacuum_failed`.
