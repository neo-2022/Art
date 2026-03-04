# PII surface

| entity | field_path | category | rule | owner_component |
|---|---|---|---|---|
| RawEvent | context.user.email | PII | redact | core/pipeline |
| RawEvent | context.client_ip | PII | redact | core/pipeline |
| Incident | actor.email | PII | redact | core/incidents |
| AuditEntry | actor.id | PII | store | core/audit |
| AttachmentMeta | filename | operational | sanitize | core/attachments |
