# Runbook: observability_gap.spatial_index_degraded

## Symptoms
- Picking latency превышает threshold.
- 3D selection sync нестабилен.

## Diagnosis
1. Проверить `layout_id/node_count/picking_ms/threshold_ms`.
2. Запустить stage35 spatial perf tests.
3. Проверить целостность index/chunks.

## Resolution
1. Перестроить spatial index.
2. Оптимизировать LOD thresholds.
3. Повторить perf tests.

## Rollback
- Переключить на предыдущую стабильную версию spatial index algorithm.
