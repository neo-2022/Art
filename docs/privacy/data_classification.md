# Классификация Данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `docs/privacy/redaction_policy.md`

## Категории
- `PII`
- `secrets`
- `telemetry`
- `operational`
- `attachments`

## Примеры
- `PII`: email, IP, username, external ids
- `secrets`: keys, tokens, cookies, auth headers
- `telemetry`: signals and measurements without direct secret value
- `operational`: system state and runtime metadata
- `attachments`: вложения, которые могут содержать PII или чувствительный контент

## Правило

Категория данных определяет redaction, access scope, retention и export policy.
