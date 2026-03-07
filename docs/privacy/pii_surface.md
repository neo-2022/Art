# PII surface

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/data_classification.md`
- `docs/privacy/redaction_policy.md`
- `docs/privacy/access_control_policy.md`

## Назначение

Этот документ фиксирует полевую карту privacy surface для всех записываемых сущностей Art.
Любое поле, попадающее в persistent storage, stream, snapshot, audit, attachment metadata или export path, должно иметь:
- `field_path`
- категорию данных
- правило обработки
- `owner_component`

Если поле не описано в этой карте, оно не считается разрешённым к хранению по умолчанию.

## Правила чтения таблицы

- `category`:
  - `PII`
  - `secrets`
  - `telemetry`
  - `operational`
  - `attachments`
- `rule`:
  - `store`
  - `redact`
  - `drop`
  - `sanitize`
- `owner_component` указывает, какой слой обязан обеспечить корректную обработку поля.

## RawEvent

| entity | field_path | category | rule | owner_component |
|---|---|---|---|---|
| RawEvent | `source_id` | operational | store | core/ingest |
| RawEvent | `source_seq` | operational | store | core/ingest |
| RawEvent | `source_ts_ms` | telemetry | store | core/ingest |
| RawEvent | `receiver_kind` | operational | store | agent/receivers |
| RawEvent | `trace_id` | operational | store | core/pipeline |
| RawEvent | `run_id` | operational | store | core/pipeline |
| RawEvent | `span_id` | operational | store | core/pipeline |
| RawEvent | `kind` | telemetry | store | core/ingest |
| RawEvent | `severity` | telemetry | store | core/ingest |
| RawEvent | `message` | telemetry | redact | core/pipeline |
| RawEvent | `payload.http.body` | PII | drop | core/ingest |
| RawEvent | `payload.http.headers.authorization` | secrets | drop | core/ingest |
| RawEvent | `payload.http.headers.cookie` | secrets | drop | core/ingest |
| RawEvent | `payload.http.headers.set-cookie` | secrets | drop | core/ingest |
| RawEvent | `payload.http.query` | PII | redact | core/pipeline |
| RawEvent | `payload.user.email` | PII | redact | core/pipeline |
| RawEvent | `payload.user.username` | PII | redact | core/pipeline |
| RawEvent | `payload.user.external_id` | PII | redact | core/pipeline |
| RawEvent | `payload.auth.token` | secrets | drop | core/pipeline |
| RawEvent | `payload.db.password` | secrets | drop | core/pipeline |
| RawEvent | `payload.file.path` | operational | store | agent/receivers |
| RawEvent | `context.client_ip` | PII | redact | browser/level0 |
| RawEvent | `context.user_agent` | PII | redact | browser/level0 |
| RawEvent | `context.hostname` | operational | store | agent/receivers |
| RawEvent | `context.service_name` | operational | store | core/ingest |
| RawEvent | `context.pod_name` | operational | store | core/ingest |
| RawEvent | `context.systemd.unit` | operational | store | agent/receivers |
| RawEvent | `context.error.stack` | telemetry | redact | core/pipeline |
| RawEvent | `otel_attributes.*` | telemetry | redact | core/ingest |

## Incident

| entity | field_path | category | rule | owner_component |
|---|---|---|---|---|
| Incident | `id` | operational | store | core/incidents |
| Incident | `incident_key` | operational | store | core/incidents |
| Incident | `status` | operational | store | core/incidents |
| Incident | `severity` | telemetry | store | core/incidents |
| Incident | `summary` | telemetry | redact | core/incidents |
| Incident | `impact` | telemetry | redact | core/incidents |
| Incident | `where` | telemetry | redact | core/incidents |
| Incident | `why` | telemetry | redact | core/incidents |
| Incident | `what_to_do` | operational | store | core/incidents |
| Incident | `scope.service` | operational | store | core/incidents |
| Incident | `scope.host` | operational | store | core/incidents |
| Incident | `scope.customer_id` | PII | redact | core/incidents |
| Incident | `scope.user_id` | PII | redact | core/incidents |
| Incident | `evidence_refs[]` | operational | store | core/incidents |
| Incident | `history[].message` | telemetry | redact | core/incidents |
| Incident | `history[].actor` | PII | redact | core/incidents |
| Incident | `history[].action_ref` | operational | store | core/incidents |

## AuditEntry

| entity | field_path | category | rule | owner_component |
|---|---|---|---|---|
| AuditEntry | `timestamp` | operational | store | core/audit |
| AuditEntry | `actor` | PII | redact | core/audit |
| AuditEntry | `actor_role` | operational | store | core/audit |
| AuditEntry | `action` | operational | store | core/audit |
| AuditEntry | `target` | operational | store | core/audit |
| AuditEntry | `result` | operational | store | core/audit |
| AuditEntry | `client_ip` | PII | redact | core/audit |
| AuditEntry | `user_agent` | PII | redact | core/audit |
| AuditEntry | `params` | secrets | redact | core/audit |
| AuditEntry | `evidence_ref` | operational | store | core/audit |
| AuditEntry | `policy_verdict` | operational | store | core/audit |

## AttachmentMeta

| entity | field_path | category | rule | owner_component |
|---|---|---|---|---|
| AttachmentMeta | `attachment_id` | operational | store | core/attachments |
| AttachmentMeta | `filename` | attachments | sanitize | core/attachments |
| AttachmentMeta | `mime_type` | attachments | store | core/attachments |
| AttachmentMeta | `size_bytes` | attachments | store | core/attachments |
| AttachmentMeta | `sha256` | operational | store | core/attachments |
| AttachmentMeta | `uploader` | PII | redact | core/attachments |
| AttachmentMeta | `source_ref` | operational | store | core/attachments |
| AttachmentMeta | `sensitivity_label` | operational | store | core/attachments |
| AttachmentMeta | `retention_class` | operational | store | core/attachments |
| AttachmentMeta | `original_path` | PII | redact | core/attachments |

## Глобальные правила

### 1. Поля по умолчанию не разрешены

Если новый `field_path` появился в:
- RawEvent
- Incident
- AuditEntry
- AttachmentMeta

и отсутствует в этой таблице, он не должен считаться разрешённым к долгому хранению.

### 2. `message`, `summary`, `impact`, `stack`

Свободный текст считается зоной повышенного риска.
Поэтому:
- default rule для таких полей не `store`, а `redact`;
- сначала применяется policy-driven redaction;
- только после этого допускается хранение/выдача.

### 3. HTTP и auth данные

Для network/http-контекста:
- body -> `drop`
- `Authorization`, `Cookie`, `Set-Cookie` -> `drop`
- query params -> `redact`

### 4. Attachments

`AttachmentMeta` и сами вложения рассматриваются как потенциальный контейнер PII/secrets.
Даже если metadata выглядит operational-safe, filename/original path/uploader могут содержать PII и обязаны проходить sanitization/redaction.

## Критерий актуальности

Документ считается актуальным только если:
- покрыты `RawEvent`, `Incident`, `AuditEntry`, `AttachmentMeta`;
- для каждой сущности указаны `field_path`, `category`, `rule`, `owner_component`;
- явно определены поля с `drop` и поля с `redact`;
- policy применима к Agent/Core/Audit/Attachments без пустых зон.
