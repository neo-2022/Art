# RAG Security Policy

## Source of truth (обязательно)
- `docs/security/secrets_policy.md`
- `docs/security/pii_secret_filter.md`
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`

## Rules
- Секреты и PII не индексируются без redaction policy.
- Загруженные пользователем документы хранятся вне git.
- Источники URL ограничены allow-list.
- Любой отказ индексатора фиксируется как diagnostic event.
