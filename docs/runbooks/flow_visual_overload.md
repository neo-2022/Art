# Runbook: observability_gap.flow_visual_overload

Событие: `observability_gap.flow_visual_overload`  
Компонент: `console/flow`

## Symptoms
- Flow Mode теряет интерактивность при штатной нагрузке.
- `p95_ms` превышает `budget_ms`.
- Auto-downgrade не активировался или активировался с опозданием.

## Diagnosis
1. Проверить payload события: `layout_id`, `node_count`, `p95_ms`, `budget_ms`, `downgrade_applied`.
2. Проверить текущий режим `flow complexity` и feature-flag advanced mode.
3. Подтвердить, что watchdog policy применена корректно.
4. Сравнить метрики до и после деградации качества.

## Resolution
1. Включить принудительный read-only fallback для Flow Mode.
2. Уменьшить visual density и motion profile до safe baseline.
3. Повторно прогнать:
   - `stage35-flow-inspectability-tests`
   - `stage35-flow-snapshot-replay-tests`
   - `stage35-flow-perf-2d-gate`
4. Снять forced fallback только после PASS всех проверок.
