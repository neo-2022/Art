# Runbook: observability_gap.console_workspace_boundary_violation

## Symptoms
- CI `workspace-boundary-check` падает.
- Найден запрещённый import между `apps/console-web` и `core/agent/browser`.

## Diagnosis
1. Запустить `bash scripts/ci/check_workspace_boundaries.sh`.
2. Считать `module/import_path/rule` из evidence события.
3. Определить запрещённый dependency edge.

## Resolution
1. Удалить запрещённый import.
2. Перенести общий код в `packages/*`.
3. Повторить `console:lint`, `console:test`, `workspace-boundary-check`.

## Rollback
- Откатить последний коммит с нарушением boundaries.
