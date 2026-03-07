# Runbook: observability_gap.checklist_ladder_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- CI `stage38-ladder-gate` падает.
- В MASTER найден `[x]` на более позднем этапе при незакрытом предыдущем.

## checks
1. Проверить `stage/previous_stage/status_matrix/rule`.
2. Запустить `bash scripts/ci/check_stage_ladder_enforcement.sh`.
3. Определить некорректную строку в MASTER.

## mitigations
1. Вернуть корректную последовательность статусов.
2. Убедиться, что для `[x]` этапа в соответствующем CHECKLIST нет `[ ]`.
3. Повторить CI gate.

## rollback
- Откатить commit со статусной ошибкой в MASTER.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.checklist_ladder_violation`.
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
