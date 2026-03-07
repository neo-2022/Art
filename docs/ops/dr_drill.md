# DR drill

## Назначение
DR drill (drill, тренировочное восстановление после аварии) нужен, чтобы команда не импровизировала в реальном инциденте,
а уже имела воспроизводимый и проверенный порядок восстановления `Art Core`.

Этот документ фиксирует **минимальный обязательный сценарий**, который должен переживать продовый storage-контур после
закрытия `stage11` и в downstream-подтверждении `stage23`.

## Сценарий drill
1. Поднять живой `Art Core` на рабочей БД.
2. Принять тестовые события через ingest.
3. Зафиксировать snapshot, incidents, audit verify и analytics до сбоя.
4. Остановить `Core`.
5. Сделать backup реальной рабочей БД Core через `sqlite3 ".backup"`.
6. Имитировать потерю узла или потерю рабочей БД.
7. Восстановить БД из backup на исходный путь.
8. Выполнить `PRAGMA integrity_check`.
9. Снова запустить `Core`.
10. Повторно проверить:
   - snapshot;
   - incidents;
   - audit verify;
   - analytics.

## Что именно подтверждает drill
Drill должен доказывать не только “БД открылась”, а что система действительно сохранила:
- принятые события;
- инцидентный контур;
- audit chain;
- аналитическую и производную информацию, которая уже должна жить в durable storage.

## Критерий PASS
Drill считается успешным, если:
- backup создан;
- backup проходит `integrity_check`;
- restored DB проходит `integrity_check`;
- после повторного запуска `Core`:
  - события видны в snapshot;
  - инциденты не потеряны;
  - `audit_verify.status = verified`;
  - analytics summary остаётся непротиворечивой.

## Критерий FAIL
Любое из ниже перечисленного:
- backup-файл не создан;
- integrity check не `ok`;
- после restore часть состояния пропала;
- audit chain сломалась;
- analytics/derived state не поднимаются обратно;
- для восстановления требуется ручная импровизация вне runbook.

## Runtime smoke
Команда боевого smoke:

```bash
bash scripts/tests/ops_stage23_smoke.sh
```

Этот smoke уже не декоративный. Он проверяет:
- живой `art-core`, а не отдельную тестовую SQLite;
- backup/restore настоящего пути `CORE_DB_PATH`;
- survive для snapshot/incidents/audit/analytics;
- сохранение stream-соединения после `SIGHUP` runtime-hook.

## Отчётность
В отчёте drill должны быть:
- дата и время;
- путь к использованному backup;
- результат integrity check;
- результат snapshot/incidents/audit/analytics после restore;
- итоговый `pass/fail`.

## Последний подтверждённый drill
- Дата: `2026-03-07`
- Контур: живой `art-core` на реальном `CORE_DB_PATH`
- Использованный backup:
  - runtime-файл вида `backups/core-YYYYMMDD-HHMMSS.sqlite3`
  - конкретный путь и имя фиксируются в evidence:
    - [stage23_ops_runtime_smoke.log](/home/art/Art/docs/governance/evidence/stage23_ops_runtime_smoke.log)
- Команды восстановления:
  - остановка `Core`
  - `sqlite3 "$CORE_DB_PATH" ".backup '$BACKUP_FILE'"`
  - `sqlite3 "$BACKUP_FILE" "PRAGMA integrity_check;"`
  - удаление исходного runtime-файла БД
  - возврат backup на `CORE_DB_PATH`
  - повторный `PRAGMA integrity_check`
  - повторный запуск `Core`
- Результаты:
  - `integrity_check` backup: `ok`
  - `integrity_check` restored DB: `ok`
  - `snapshot_before_events = 1`
  - `snapshot_after_events = 1`
  - `incidents_before = 1`
  - `incidents_after = 1`
  - `audit_verify_before = verified`
  - `audit_verify_after = verified`
  - `analytics_total_events_after = 2`
- Итог: `pass`
