# Runbook: observability_gap.saas_tenant_isolation_failed

## Symptoms
- Обнаружен cross-tenant доступ.
- Isolation tests failed.

## Diagnosis
1. Проверить `tenant_id/resource/policy_id/error`.
2. Запустить stage36 isolation suite.
3. Проверить control-plane/data-plane authorization path.

## Resolution
1. Закрыть уязвимый policy path.
2. Включить deny-by-default для неоднозначных контекстов.
3. Повторить isolation tests.

## Rollback
- Изолировать затронутый tenant и откатить policy config до предыдущего стабильного состояния.
