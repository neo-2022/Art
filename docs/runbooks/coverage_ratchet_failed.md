# Runbook: observability_gap.coverage_ratchet_failed

## Symptoms
- CI coverage ratchet gate failed.
- Покрытие модуля ниже baseline.

## Diagnosis
1. Проверить `module/metric/baseline/actual`.
2. Сверить изменения тестов и кода.
3. Выявить непокрытые ветки.

## Resolution
1. Добавить недостающие тесты.
2. Повторить `check_coverage_ratchet_v0_2.sh`.
3. Обновить baseline только после утверждения.

## Rollback
- Откатить изменения, которые снизили coverage ниже baseline.
