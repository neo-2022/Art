# Runbook: metrics_unavailable

## mitigations
1. Проверить доступность `/metrics` и состояние Core.
2. Проверить сетевой путь/балансировщик.
3. Повторить scrape после восстановления.

## verification
- `/metrics` отвечает HTTP 200;
- новых `observability_gap.metrics_unavailable` нет.
