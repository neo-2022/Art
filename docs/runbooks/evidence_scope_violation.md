# Runbook: observability_gap.evidence_scope_violation

## Symptoms
- Доступ к evidence выдаётся вне разрешённого scope.
- В журналах есть `required_scope` mismatch.

## Diagnosis
1. Проверить `evidence_id/required_scope/actor_role`.
2. Запустить `cargo test -p art-core v2_evidence_access_scope_enforcement_tests`.
3. Проверить policy mapping ролей.

## Resolution
1. Исправить scope enforcement logic.
2. Включить deny-by-default для неизвестных scope.
3. Прогнать stage30 tests.

## Rollback
- Временно ограничить доступ к endpoint `/api/v2/evidence/*` до admin-only.
