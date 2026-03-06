# Runbook: observability_gap.checklist_ladder_violation

## Symptoms
- CI `stage38-ladder-gate` падает.
- В MASTER найден `[x]` на более позднем этапе при незакрытом предыдущем.

## Diagnosis
1. Проверить `stage/previous_stage/status_matrix/rule`.
2. Запустить `bash scripts/ci/check_stage_ladder_enforcement.sh`.
3. Определить некорректную строку в MASTER.

## Resolution
1. Вернуть корректную последовательность статусов.
2. Убедиться, что для `[x]` этапа в соответствующем CHECKLIST нет `[ ]`.
3. Повторить CI gate.

## Rollback
- Откатить commit со статусной ошибкой в MASTER.
