# Runbook: observability_gap.api_dual_write_mismatch

## Symptoms
- Расхождение данных между v1/v2 путями.
- Верификатор dual-write фиксирует matured mismatch (после окна допустимой задержки доставки).

## Diagnosis
1. Сверить v1/v2 payload для одного trace_id.
2. Проверить, что trace_id вышел из `delivery_lag_grace_window` (default `10s`; pending записи не считаются mismatch).
3. Проверить миграцию `events_v2/dna_clusters/evidence_blocks`.
4. Прогнать stage29 suite.

## Resolution
1. Остановить rollout API v2 изменений.
2. Исправить mapper/adapters и миграцию.
3. Повторить dual-write verification до `normalized mismatch rate = 0` на matured наборе.
