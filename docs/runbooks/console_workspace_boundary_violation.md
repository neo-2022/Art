# Runbook: observability_gap.console_workspace_boundary_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- CI `workspace-boundary-check` падает.
- Найден запрещённый import между `apps/console-web` и `core/agent/browser`.

## checks
1. Запустить `bash scripts/ci/check_workspace_boundaries.sh`.
2. Считать `module/import_path/rule` из evidence события.
3. Определить запрещённый dependency edge.

## mitigations
1. Удалить запрещённый import.
2. Перенести общий код в `packages/*`.
3. Повторить `console:lint`, `console:test`, `workspace-boundary-check`.

## rollback
- Откатить последний коммит с нарушением boundaries.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.console_workspace_boundary_violation`.
- Snapshot/stream/метрики подтверждают восстановление без новых regressions.
- Смежные hostile paths не деградировали после remediation.

## escalation
- Эскалировать on-call и Incident Commander, если mitigation не восстановила сервис в рамках SLA severity.
- При SEV1+ или повторном срабатывании приложить evidence refs и связанный incident/postmortem trail.

## evidence
- Сохранить event payload, `trace_id`/`request_id`/`audit_id`, affected component, version/build, config diff и relevant log excerpts.
- Для UI/runtime проблем приложить screenshot/video reproduction и browser/runtime context.
- Для release/config проблем приложить commit/tag/PR и rollback decision.

## owner
- Основной владелец: дежурный инженер и компонент-владелец по RACI/реестру событий.
- Ответственный за эскалацию: Incident Commander для SEV1+ или затяжного инцидента.

## degraded mode
- Если полное восстановление недоступно, включить документированный degraded/read-only mode для затронутой поверхности.
- Зафиксировать scope деградации, срок действия и условие выхода из degraded mode.
