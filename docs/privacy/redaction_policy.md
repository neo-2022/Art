# Redaction policy

Применение redaction: message/payload/context/attachments meta/audit pre-write.

## configurable rules
- rules хранятся в конфиге
- rules версионируются
- есть rollout/rollback

## privacy.redaction_applied
Событие обязательно при любом применении redaction:
- timestamp
- rule_id
- field_paths
- redaction_count
- owner_component

## observability_gap.redaction_failed
При ошибке redaction генерируется `observability_gap.redaction_failed`.
Содержит evidence_min: error, context, counters.
Событие регистрируется в `docs/governance/observability_gap_registry.md` с incident_rule и action_ref.
