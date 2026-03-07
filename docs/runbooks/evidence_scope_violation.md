# Runbook: observability_gap.evidence_scope_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Доступ к evidence выдаётся вне разрешённого scope.
- В журналах есть `required_scope` mismatch.

## checks
1. Проверить `evidence_id/required_scope/actor_role`.
2. Запустить `cargo test -p art-core v2_evidence_access_scope_enforcement_tests`.
3. Проверить policy mapping ролей.

## mitigations
1. Исправить scope enforcement logic.
2. Включить deny-by-default для неизвестных scope.
3. Прогнать stage30 tests.

## rollback
- Временно ограничить доступ к endpoint `/api/v2/evidence/*` до admin-only.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.evidence_scope_violation`.
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
