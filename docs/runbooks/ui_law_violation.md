# Runbook: observability_gap.ui_law_violation

## Symptoms
- Нарушены инварианты tooltip/evidence-link/evidence-refs.
- Runtime law checks фиксируют критичное нарушение.

## Diagnosis
1. Определить law_version и rule_id.
2. Проверить статические lint-тесты и runtime sample logs.
3. Воспроизвести нарушение в console/panel0 test suite.

## Resolution
1. Заблокировать release при критичном нарушении.
2. Исправить компонент и добавить regression test.
3. Повторно прогнать stage30 + console-test.
