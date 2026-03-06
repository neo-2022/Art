# Runbook: observability_gap.action_preflight_missing

## Symptoms
- Action execute пришёл без preflight.
- Policy log неполный.

## Diagnosis
1. Проверить `action/target/actor_role/policy_id`.
2. Запустить stage33 action protocol tests.
3. Проверить Action Studio request builder.

## Resolution
1. Обязать preflight request в UI/API.
2. Блокировать execution без preflight.
3. Перезапустить tests и verify chain.

## Rollback
- Временно запретить affected action type до восстановления preflight path.
