# Startup Configuration Safety Validator v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/risk_register_v0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`

## Назначение
Этот документ задаёт fail-closed baseline для запуска `Core`, `Agent`, browser/runtime и deployment-контуров.

## Обязательные свойства
1. Система не имеет права стартовать в опасной конфигурации "а потом разбираться".
2. Критичные unsafe-конфигурации должны блокировать старт до первого внешнего воздействия.
3. Отказ запуска должен быть наблюдаемым и объяснимым.

## Обязательные классы unsafe-конфига
- internet-facing `plain HTTP`, если policy требует TLS;
- пустой или неверный путь к storage/spool/backup;
- недопустимо большие batch/queue/timeout лимиты;
- отключённый audit / trusted boundary / release blocker bypass в production-profile;
- несогласованный profile / transport / relay path.

## Fail-closed правило
Если startup validator не может подтвердить безопасность конфигурации, система обязана:
- отказаться от старта или перехода в `ready` state;
- записать диагностический reason;
- сгенерировать `observability_gap.unsafe_startup_config_refused`.

## Gap событие
- `observability_gap.unsafe_startup_config_refused`
- evidence minimum:
  - `component`
  - `config_key`
  - `reason`
  - `deployment_profile`
  - `trace_id`

## Связанные runbooks
- `docs/runbooks/unsafe_startup_config_refused.md`
