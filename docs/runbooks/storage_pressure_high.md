# Runbook: storage pressure high

## Сигналы
- `observability_gap.storage_pressure_high`
- снижение `free_bytes`
- рост `db_used_bytes` или `wal_used_bytes`
- учащение `503 + retry_after_ms` на write-path

## Диагностика
1. Проверить свободное место на storage path и backup path.
2. Проверить размер SQLite DB и WAL.
3. Проверить, не идёт ли hostile burst, duplicate flood или runaway integration.
4. Проверить, сработал ли housekeeping / archive / prune.

## Ремедиация
`mitigations`

1. Включить controlled degraded mode, если он ещё не включился автоматически.
2. Освободить место или расширить storage budget по политике.
3. Проверить и остановить источник, который вызывает runaway growth.
4. После стабилизации повторно подтвердить writable mode и integrity.

## Проверка
`verification`

- `free_bytes` выше reserve threshold
- `Core` вернулся из degraded mode
- новых `storage_pressure_high` событий нет на контрольном окне
