# Storage Pressure Protection v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/governance/observability_gap_registry.md`

## Назначение
Этот документ задаёт production-baseline защиты storage от медленного удушения диска, WAL и SQLite при flood, DDoS, багнутой интеграции или долгом росте данных.

## Что это значит простыми словами
`storage pressure` означает, что место на файловой системе ещё не закончилось полностью, но запас свободного пространства уже настолько мал, что `Core` обязан заранее замедлить или остановить запись, вместо того чтобы молча дойти до полного `disk full`.

Этот контур нужен для двух разных сценариев:
1. короткий burst, который быстро забивает локальный storage;
2. медленный, но устойчивый поток, который выглядит "законным", однако за часы или дни всё равно доводит БД до отказа.

## Материализованный baseline
- `Core` вычисляет состояние storage по реальному пути SQLite БД.
- В расчёт входят:
  - размер основной БД;
  - размер WAL;
  - свободное место на файловой системе;
  - зарезервированный запас свободного пространства.
- Два рабочих порога уже materialized:
  - `high watermark`
  - `critical watermark`
- Конфигурация задаётся через:
  - `CORE_STORAGE_HIGH_WATERMARK_PERCENT`
  - `CORE_STORAGE_CRITICAL_WATERMARK_PERCENT`
  - `CORE_STORAGE_RESERVED_FREE_SPACE_MB`

## Обязательные свойства
1. `Core` обязан отслеживать не только corruption, но и storage pressure.
2. До фактического `disk full` должны существовать как минимум два порога:
- `high watermark`
- `critical watermark`
3. При `high watermark` система обязана:
- поднять `observability_gap.storage_pressure_high`;
- начать controlled shed и снизить ingest pressure;
- пропускать только лёгкие write-path;
- включить ускоренный housekeeping / archive / prune policy.
4. При `critical watermark` система обязана:
- перевести ingest в жёсткий degraded mode;
- вернуть `503 + retry_after_ms` уже и для обычных write-path;
- не допустить тихого разрушения БД.
5. Резерв свободного места (`reserve free space` / `reserved free space`) должен быть фиксированным и контролируемым.

## Текущее runtime-поведение
### Режим `high`
- `Core` генерирует `observability_gap.storage_pressure_high`;
- в `snapshot`/`stream` появляется событие с `pressure_state=high`;
- тяжёлые write-path (например, batch ingest) получают `503 + retry_after_ms`;
- лёгкие write-path ещё допускаются, чтобы система могла пережить короткий всплеск без полной остановки.

### Режим `critical`
- `Core` снова генерирует `observability_gap.storage_pressure_high`, но уже с `pressure_state=critical`;
- обычные write-path тоже начинают получать `503 + retry_after_ms`;
- система уходит в более жёсткий degraded mode, чтобы не добить SQLite до фактического `disk full`.

### Возврат к норме
- если свободное место возвращается выше защищённого порога, `Core` обязан вернуться в `normal`;
- после этого write-path снова начинают принимать запросы без ручной правки БД;
- этот recovery path уже подтверждён hostile runtime smoke.

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

## Чем `storage pressure` отличается от `disk full`
- `storage pressure` — это раннее предупреждение и управляемая деградация до полного отказа;
- `disk full` — это уже фактическое исчерпание места, когда SQLite или файловая система перестают принимать запись.

Проект обязан различать эти два состояния, потому что:
- иначе оператор увидит проблему слишком поздно;
- невозможно будет понять, система предупредила заранее или просто рухнула в последний момент.

## Что считается нарушением
Нарушением baseline считается ситуация, когда:
- диск почти заполнен, но система ещё не перешла в controlled degraded mode;
- `Core` молча продолжает принимать запись до `SQLITE_FULL`;
- давление storage видно только в ручной диагностике, но не в gap/event/evidence path.

## Что уже materialized дополнительно
- live hostile proof именно для фактического `disk full`;
- автоматическая archive/prune discipline как часть защитного контура;
- recovery после увеличения доступного storage budget без ручной правки БД;
- evidence `stage11_storage_pressure_runtime.log`, в котором зафиксированы:
  - `high -> critical -> recover`;
  - `disk full -> 503 + retry_after_ms`;
  - `storage_archive_prune_activated`;
  - уменьшение количества backup с `8` до `2`.

## Что ещё остаётся незавершённым
Этот документ описывает уже materialized runtime-baseline, но не выдаёт его за полностью завершённый production contour по всему дереву стадий.

Открытым остаётся:
- обязательная release-grade связка с `stage24`;
- обязательная Linux/runtime hardening связка с `stage37`;
- перенос этого baseline в `ingest`- и perimeter-level protective contours `stage12/24/37`.

## Связанные runbooks
- `docs/runbooks/storage_pressure_high.md`
- `docs/ops/storage.md`
- `docs/ops/backup_restore_sqlite.md`
