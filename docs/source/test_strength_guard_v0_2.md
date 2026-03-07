# Test Strength Guard v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/test_system_audit_v0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`

## Что это такое
Это предохранитель, который не даёт критичным контурам жить на декоративных или слишком слабых тестах.

## Основная идея
Для важного production-контура недостаточно:
- проверить наличие файла;
- найти строку через `grep`;
- проверить HTML-фрагмент;
- увидеть один happy-path.

## Что требуется
Критичный контур должен иметь нужные классы проверки:
- contract;
- behavior;
- integration;
- operational;
- adversarial;
- regression.

## Что считается слабым тестовым контуром
- только structural/doc checks;
- только snapshot/string checks;
- нет hostile сценариев;
- нет regression proof;
- нет operational evidence.

## Observability и реакция
Gap:
- `observability_gap.test_strength_guard_failed`

## Связанные runbooks
- `docs/runbooks/test_strength_guard_failed.md`
