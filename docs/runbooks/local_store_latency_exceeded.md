# Runbook: observability_gap.local_store_latency_exceeded

## Symptoms
- p95 local-store операций выше budget.
- UI лагает при поиске/индексации.

## Diagnosis
1. Определить store_type и operation.
2. Проверить worker offload и batch size.
3. Проверить incremental-index path.

## Resolution
1. Переключить heavy path в worker.
2. Оптимизировать индексы/ключи/батчинг.
3. Повторить stage34 perf/load suites.
