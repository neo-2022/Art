# Profile guards

Проверки:
- retention
- export
- egress
- residency
- updates/packs

Правило: fail closed (блокировать запуск/применение при нарушении).

## observability_gap.profile_violation
- Событие обязательно попадает в snapshot/stream.
- evidence_min: violated_rule, profile_id, parameter, current_values.
- Реестр: `docs/governance/observability_gap_registry.md`.
- action_ref: `docs/runbooks/profile_violation.md`.
