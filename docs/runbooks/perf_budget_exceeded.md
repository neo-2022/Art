# Runbook: observability_gap.perf_budget_exceeded

## Symptoms
- p95/p99 превышают бюджет.
- Stage34 perf gate падает.

## Diagnosis
1. Проверить `suite/metric/actual/budget`.
2. Сравнить с baseline perf report.
3. Локализовать регрессионный компонент.

## Resolution
1. Устранить регрессию.
2. Повторить load/perf regression suite.
3. Обновить отчёт с фактическими значениями.

## Rollback
- Вернуть предыдущую стабильную версию компонента с допустимой производительностью.
