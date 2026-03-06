# Политика Редакции Данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `docs/governance/observability_gap_registry.md`

## Где Применяется Redaction
- `message`
- `payload`
- `context`
- `attachments meta`
- `audit pre-write`

## Обязательные Правила
- правила redaction хранятся в конфиге
- `configurable rules` являются обязательным baseline: правила задаются конфигом, а не захардкоженными строками
- правила версионируются
- для правил должен существовать rollout/rollback

## Обязательное Событие

При каждом применении redaction фиксируется `privacy.redaction_applied` с минимальным набором:
- `timestamp`
- `rule_id`
- `field_paths`
- `redaction_count`
- `owner_component`

## Ошибка Redaction

При сбое redaction формируется `observability_gap.redaction_failed`.

Событие должно быть зарегистрировано в registry с `incident_rule` и `action_ref`.
