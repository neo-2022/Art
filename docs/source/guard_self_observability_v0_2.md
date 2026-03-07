# Guard Self-Observability v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`

## Назначение
Этот документ задаёт baseline для самонаблюдаемости защитных механизмов. Предохранитель, который не умеет сообщить о своей деградации, не считается полноценной защитой.

## Обязательные свойства
1. Каждый критичный guard должен иметь self-test или self-check.
2. Каждый критичный guard должен иметь heartbeat/health signal.
3. Ошибка guard должна становиться отдельным `observability_gap.*`, а не теряться в логах CI.
4. Release и stage closure не имеют права опираться на guard, который сам неисправен.

## Что относится к guard-классу
- ingress shield;
- startup validator;
- trust boundary validator;
- browser surface policy checks;
- documentation/root sync guards;
- defect/stage ladder guards;
- authenticity guard.

## Gap событие
- `observability_gap.guard_self_test_failed`
- evidence minimum:
  - `guard_name`
  - `failure_mode`
  - `last_success_ts`
  - `stage_context`
  - `trace_id`

## Связанные runbooks
- `docs/runbooks/guard_self_test_failed.md`
