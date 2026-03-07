# Runbook: observability_gap.perf_budget_exceeded

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- p95/p99 превышают бюджет.
- Stage34 perf gate падает.

## checks
1. Проверить `suite/metric/actual/budget`.
2. Сравнить с baseline perf report.
3. Локализовать регрессионный компонент.

## mitigations
1. Устранить регрессию.
2. Повторить load/perf regression suite.
3. Обновить отчёт с фактическими значениями.

## rollback
- Вернуть предыдущую стабильную версию компонента с допустимой производительностью.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.perf_budget_exceeded`.
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
