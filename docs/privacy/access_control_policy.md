# Access control policy (attachments)

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/attachments_security.md`
- `docs/governance/audit_policy.md`

## Назначение

Документ задаёт baseline least-privilege policy для attachments и attachment metadata.

## Роли доступа

### `viewer`
- без доступа к attachment bytes
- без доступа к потенциально чувствительным attachment metadata
- может видеть только безопасный existence/status marker, если это разрешено UI policy

### `operator`
- может читать metadata в объёме, необходимом для расследования
- не получает bytes автоматически
- доступ к bytes только через отдельный policy gate

### `admin`
- может читать metadata
- может читать bytes по необходимости и при наличии operational justification
- доступ должен попадать в audit trail

## Public by default запрещён

Жёсткое правило:
- attachments не могут быть public by default;
- attachment bytes не могут утекать через анонимный URL, общий export path или UI без RBAC/policy gate;
- metadata также не считается автоматически безопасной, потому что filename, uploader и original path могут содержать PII.

## Логирование

Жёсткое правило логирования:
- attachment bytes не пишутся в логи;
- PII metadata без redaction не пишутся в логи;
- debug path не должен обходить это правило.

Разрешено логировать:
- attachment id
- mime type
- size_bytes
- sensitivity label
- retention class

Запрещено логировать без redaction:
- original filename, если он содержит PII/path data
- original path
- uploader identity
- excerpt content

## Выдача наружу

Любая выдача attachment bytes или metadata наружу:
- идёт через role/policy check;
- должна быть auditable;
- должна уважать profile restrictions и privacy baseline.

## Критерий актуальности

Документ считается актуальным только если:
- перечислены роли доступа к attachments;
- явно запрещён `public by default`;
- явно указано, что attachment bytes не пишутся в логи;
- явно указано, что PII metadata без redaction не логируются.
