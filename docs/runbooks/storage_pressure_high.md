# Runbook: storage pressure high

## Сигналы
- `observability_gap.storage_pressure_high`
- при более жёстком сценарии дополнительно может появиться `observability_gap.storage_archive_prune_activated`
- снижение `free_bytes`
- рост `db_used_bytes` или `wal_used_bytes`
- учащение `503 + retry_after_ms` на write-path

## Что это означает
Система ещё не потеряла storage полностью, но уже подошла к границе, после которой запись может начать разрушать рабочее состояние SQLite.

Это ранний защитный сигнал. Его смысл не в том, чтобы “просто записать предупреждение в лог”, а в том, чтобы:
- вовремя предупредить оператора;
- включить controlled degradation;
- не дойти до фактического `disk full`.

## Диагностика
1. Проверить свободное место на storage path и backup path.
2. Проверить размер SQLite DB и WAL.
3. Проверить, не идёт ли hostile burst, duplicate flood или runaway integration.
4. Проверить, сработал ли housekeeping / archive / prune.
5. Проверить, в каком именно режиме находится система:
   - `high`
   - `critical`
6. Проверить, какие write-path уже начали получать `503`.

## Ремедиация
`mitigations`

1. Включить controlled degraded mode, если он ещё не включился автоматически.
2. Освободить место или расширить storage budget по политике.
3. Проверить и остановить источник, который вызывает runaway growth.
4. Если рост вызван не атакой, а долгим легальным потоком, проверить retention, archive и prune policy.
5. Если уже сработал `archive/prune`, проверить:
   - сколько backup было удалено;
   - сколько места освобождено;
   - не нарушена ли retention policy.
6. После стабилизации повторно подтвердить writable mode и integrity.

## Проверка
`verification`

- `free_bytes` выше reserve threshold
- `Core` вернулся из degraded mode
- новых `storage_pressure_high` событий нет на контрольном окне
- если срабатывал `archive/prune`, событие `observability_gap.storage_archive_prune_activated` подтверждает контролируемое освобождение места
- `storage_pressure_state=normal`
- write-path снова принимает обычные запросы
- `integrity check` не показывает повреждений
