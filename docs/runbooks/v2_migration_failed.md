# Runbook: observability_gap.v2_migration_failed

## Symptoms
- Migration этап v2 завершился ошибкой.
- API v2 отвечает нестабильно после deploy.

## Diagnosis
1. Проверить `migration_id/db_path/stage/error`.
2. Сверить шаги с `docs/contracts/v2/migrations_v2.md`.
3. Подтвердить состояние v1 endpoints.

## Resolution
1. Выполнить rollback sequence из migration doc.
2. Восстановить dual-read безопасный режим.
3. Повторить canary verification.

## Rollback
- Откат на предыдущий stable tag с v1-only traffic.
