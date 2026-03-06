# Runbook: observability_gap.dna_determinism_violation

## Symptoms
- Один и тот же replay даёт разные `dna_id`/cluster boundaries.
- Canary validator расходится с primary pipeline.

## Diagnosis
1. Проверить `dna_schema_version` и последний deploy SHA.
2. Сравнить canonical payload hashes для одинаковых raw events.
3. Прогнать:
   - `bash scripts/ci/run_stage29_dna_tests.sh`
   - `bash scripts/ci/run_stage29_dna_property_million.sh`
4. Проверить, нет ли drift между моделью и кодом (`docs/contracts/v2/dna_model/*`).

## Resolution
1. Остановить rollout DNA Core.
2. Переключить feature flag `dna_core_v2_enabled=0` (fallback raw-events mode).
3. Сгенерировать reproducible fixture и добавить regression тест.
4. Выпустить фикс, повторно пройти stage29+stage34 gates.
