# Runbook: observability_gap.action_preflight_missing

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Action execute пришёл без preflight.
- Policy log неполный.

## checks
1. Проверить `action/target/actor_role/policy_id`.
2. Запустить stage33 action protocol tests.
3. Проверить Action Studio request builder.

## mitigations
1. Обязать preflight request в UI/API.
2. Блокировать execution без preflight.
3. Перезапустить tests и verify chain.

## rollback
- Временно запретить affected action type до восстановления preflight path.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.action_preflight_missing`.
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
