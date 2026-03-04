# Access control policy (attachments)

Роли:
- viewer: без доступа к bytes
- operator: read metadata
- admin: read metadata + bytes по необходимости

Правило: public by default запрещён.
Логирование: attachment bytes не пишем; PII metadata без redaction не логируем.
