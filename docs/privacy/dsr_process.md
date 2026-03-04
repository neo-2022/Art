# DSR process

Шаги: export / delete / rectify.

Идентификация субъекта: user_id, email, external_id.

Правило: AuditEntry append-only, не редактируется задним числом; PII/Secrets redacted pre-write.
Ссылки: `docs/privacy/retention_matrix.md`, `docs/governance/audit_policy.md`.
