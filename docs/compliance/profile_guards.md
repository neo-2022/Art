# Profile guards

Проверки:
- retention
- export
- egress
- residency
- updates/packs

Правило: fail closed (блокировать запуск/применение при нарушении).

Применение профиля в runtime:
- `POST /api/v1/profile/apply`
- При нарушении guardrails: HTTP 400 и профиль не применяется (fail closed).

## observability_gap.profile_violation
- Событие обязательно попадает в snapshot/stream.
- evidence_min: violated_rule, profile_id, parameter, current_values.
- Реестр: `docs/governance/observability_gap_registry.md`.
- action_ref: `docs/runbooks/profile_violation.md`.
