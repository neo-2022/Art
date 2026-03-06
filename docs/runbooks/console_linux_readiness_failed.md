# Runbook: observability_gap.console_linux_readiness_failed

## Symptoms
- Linux readiness suite Console не проходит.
- Rollout заблокирован alert gate.

## Diagnosis
1. Проверить `suite/scenario/error/build_id`.
2. Запустить `scripts/tests/console_linux_prod_readiness.sh` локально.
3. Сверить состояние Core snapshot/stream.

## Resolution
1. Исправить failing scenario.
2. Повторить readiness suite на canary.
3. Подтвердить отсутствие regression alert.

## Rollback
- Вернуться на previous stable tag и повторить readiness verification.
