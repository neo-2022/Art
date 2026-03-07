# Runbook: observability_gap.coverage_ratchet_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- CI coverage ratchet gate failed.
- Покрытие модуля ниже baseline.

## checks
1. Проверить `module/metric/baseline/actual`.
2. Сверить изменения тестов и кода.
3. Выявить непокрытые ветки.

## mitigations
1. Добавить недостающие тесты.
2. Повторить `check_coverage_ratchet_v0_2.sh`.
3. Обновить baseline только после утверждения.

## rollback
- Откатить изменения, которые снизили coverage ниже baseline.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.coverage_ratchet_failed`.
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
