# Storage Pressure Protection v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/governance/observability_gap_registry.md`

## Назначение
Этот документ задаёт production-baseline защиты storage от медленного удушения диска, WAL и SQLite при flood, DDoS, багнутой интеграции или долгом росте данных.

## Обязательные свойства
1. `Core` обязан отслеживать не только corruption, но и storage pressure.
2. До фактического `disk full` должны существовать как минимум два порога:
- `high watermark`
- `critical watermark`
3. При `high watermark` система обязана:
- поднять `observability_gap.storage_pressure_high`;
- начать controlled shed и снизить ingest pressure;
- включить ускоренный housekeeping / archive / prune policy.
4. При `critical watermark` система обязана:
- перевести ingest в жёсткий degraded mode;
- вернуть `503 + retry_after_ms` для новых write-heavy paths;
- не допустить тихого разрушения БД.
5. Резерв свободного места (`reserve free space` / `reserved free space`) должен быть фиксированным и контролируемым.

## Обязательные сигналы
- `db_used_bytes`
- `wal_used_bytes`
- `free_bytes`
- `storage_pressure_state`
- `retry_after_ms`

## Gap событие
- `observability_gap.storage_pressure_high`
- evidence minimum:
  - `db_path`
  - `free_bytes`
  - `db_used_bytes`
  - `wal_used_bytes`
  - `pressure_state`
  - `retry_after_ms`
  - `trace_id`

## Что считается нарушением
Нарушением baseline считается ситуация, когда:
- диск почти заполнен, но система ещё не перешла в controlled degraded mode;
- `Core` молча продолжает принимать запись до `SQLITE_FULL`;
- давление storage видно только в ручной диагностике, но не в gap/event/evidence path.

## Связанные runbooks
- `docs/runbooks/storage_pressure_high.md`
- `docs/ops/storage.md`
- `docs/ops/backup_restore_sqlite.md`
