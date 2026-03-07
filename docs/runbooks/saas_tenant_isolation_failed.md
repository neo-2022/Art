# Runbook: observability_gap.saas_tenant_isolation_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Обнаружен cross-tenant доступ.
- Isolation tests failed.

## checks
1. Проверить `tenant_id/resource/policy_id/error`.
2. Запустить stage36 isolation suite.
3. Проверить control-plane/data-plane authorization path.

## mitigations
1. Закрыть уязвимый policy path.
2. Включить deny-by-default для неоднозначных контекстов.
3. Повторить isolation tests.

## rollback
- Изолировать затронутый tenant и откатить policy config до предыдущего стабильного состояния.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.saas_tenant_isolation_failed`.
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
