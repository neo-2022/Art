# Stage Ladder Enforcement

Последняя актуализация: 2026-03-06

## Правило
Этап N+1 не может быть `[x]`, если этап N остаётся `[ ]` в MASTER.

## Source of truth
`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Автоматизация
- `scripts/ci/check_stage_ladder_enforcement.sh`
- CI job `stage38-ladder-gate`
- Источник runtime-состояния инцидентов: `docs/ops/runtime_incident_status.json`

## Отказоустойчивость процесса
При нарушении лестницы CI блокирует merge до восстановления корректной последовательности статусов.
Если открыты `open_determinism_incidents` или `open_canary_divergence_incidents`, stage38 gate возвращает FAIL.
