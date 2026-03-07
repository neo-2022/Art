# Runbook: observability_gap.evidence_privacy_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Evidence выдан/сохранён с нарушением access_scope/redaction policy.
- Обнаружен доступ к PII вне разрешённой области.

## checks
1. Сверить actor_role, required_scope, effective_profile_id.
2. Проверить redaction_policy_id и retention.
3. Проверить audit trail по evidence_id.

## mitigations
1. Немедленно ограничить доступ и изолировать affected scope.
2. Выполнить redaction/removal/anonymization workflow.
3. Провести RCA и повторить privacy compliance tests.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.evidence_privacy_violation`.
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
