# Политика редакции данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/data_classification.md`
- `docs/privacy/pii_surface.md`
- `docs/governance/observability_gap_registry.md`

## Назначение

Этот документ фиксирует единый redaction baseline для Art:
- где применяется redaction;
- какие `field_paths` покрыты;
- какие `rule_id` являются каноническими;
- как versioned/configurable rules выкатываются и откатываются;
- как формируется `privacy.redaction_applied`;
- что происходит при failure-mode.

## Где применяется redaction

Redaction обязателен до долговременной записи и до внешней выдачи для следующих источников:
- `message`
- `payload`
- `context`
- `attachments meta`
- `attachment preview/excerpt`
- `audit pre-write`
- `investigation export`
- `ui/api outward rendering`

Жёсткое правило:
- redaction применяется ДО записи в AuditEntry;
- redaction применяется ДО выдачи наружу (UI/API);
- redaction применяется ДО записи в spool/outbox там, где речь идёт о `secrets` и запрещённых сырых значениях.

## Канонические `rule_id`

| rule_id | Назначение | Действие |
|---|---|---|
| `redact.email.v1` | email и email-like values | `redact` |
| `redact.ip.v1` | IP и client network ids | `redact` |
| `redact.user_identifier.v1` | username / external id / employee id | `redact` |
| `drop.http_body.v1` | HTTP request/response body | `drop` |
| `drop.auth_header.v1` | `Authorization` и аналоги | `drop` |
| `drop.cookie.v1` | `Cookie` / `Set-Cookie` | `drop` |
| `drop.secret_token.v1` | API tokens / bearer tokens / session tokens | `drop` |
| `redact.query_param.v1` | query params с user/sensitive meaning | `redact` |
| `redact.audit_actor.v1` | actor fields в audit | `redact` |
| `sanitize.attachment_filename.v1` | небезопасные filename/path fragments | `sanitize` |
| `redact.stack_sensitive.v1` | stack/message with embedded PII/secrets | `redact` |

## Полевая область применения (`field_paths`)

| field_path | rule_id | owner_component |
|---|---|---|
| `payload.user.email` | `redact.email.v1` | `core/pipeline` |
| `payload.user.username` | `redact.user_identifier.v1` | `core/pipeline` |
| `payload.user.external_id` | `redact.user_identifier.v1` | `core/pipeline` |
| `context.client_ip` | `redact.ip.v1` | `browser/level0` |
| `context.user_agent` | `redact.ip.v1` | `browser/level0` |
| `payload.http.body` | `drop.http_body.v1` | `core/ingest` |
| `payload.http.headers.authorization` | `drop.auth_header.v1` | `core/ingest` |
| `payload.http.headers.cookie` | `drop.cookie.v1` | `core/ingest` |
| `payload.http.headers.set-cookie` | `drop.cookie.v1` | `core/ingest` |
| `payload.auth.token` | `drop.secret_token.v1` | `core/pipeline` |
| `payload.db.password` | `drop.secret_token.v1` | `core/pipeline` |
| `payload.http.query` | `redact.query_param.v1` | `core/pipeline` |
| `message` | `redact.stack_sensitive.v1` | `core/pipeline` |
| `context.error.stack` | `redact.stack_sensitive.v1` | `core/pipeline` |
| `actor` | `redact.audit_actor.v1` | `core/audit` |
| `AttachmentMeta.filename` | `sanitize.attachment_filename.v1` | `core/attachments` |
| `AttachmentMeta.original_path` | `sanitize.attachment_filename.v1` | `core/attachments` |

## Требование configurable rules

`configurable rules` являются обязательным baseline: правила задаются конфигом, а не захардкоженными строками в бизнес-логике.

### Где хранится конфиг rules

Канонический путь конфигурации:
- `config/privacy/redaction_rules.yaml`

Допустимый runtime override:
- profile-specific overlay через `effective_profile_id`
- environment-specific overlay через policy bundle, но без изменения базовой схемы `rule_id`

### Как версионируются rules

- каждая запись имеет стабильный `rule_id`
- изменение семантики существующего правила требует version bump (`*.v2`, `*.v3`)
- изменение only rollout state без смены семантики version bump не требует

### Как происходит rollout / rollback rules

- rollout через изменение конфигурации, а не через перекомпиляцию/релиз кода
- rollout должен быть:
  - versioned
  - auditable
  - revertable
- rollback выполняется возвратом к предыдущей версии policy bundle / rules config

## `privacy.redaction_applied`

При каждом фактическом применении redaction, которое изменило исходные данные, обязателен event:
- `privacy.redaction_applied`

Минимальное содержимое события:
- `timestamp`
- `rule_id`
- `field_paths`
- `redaction_count`
- `owner_component`

Дополнительно рекомендуется фиксировать:
- `source_kind`
- `entity_type`
- `effective_profile_id`
- `trace_id`

Жёсткое правило:
- событие пишется всегда, если redaction реально изменила данные;
- если правило было проверено, но изменения не потребовались, событие не должно генерироваться как ложный positive.

## `observability_gap.redaction_failed`

При невозможности применить redaction формируется:
- `observability_gap.redaction_failed`

### Условия генерации

- сломан конфиг rules
- неизвестная схема объекта
- исключение фильтра/redactor
- profile overlay конфликтует с baseline rules
- attachment sanitizer не смог безопасно обработать metadata

### Минимальные поля evidence

- `error_class`
- `error_message`
- `owner_component`
- `field_paths`
- `rule_id`, если rule уже был выбран
- `entity_type`
- `counter`
- `trace_id`, если доступен

### Связь с incident path

Событие должно быть зарегистрировано в:
- `docs/governance/observability_gap_registry.md`

с обязательными полями:
- `incident_rule`
- `action_ref`

## Глобальные правила

1. Redaction не может быть отложен “до UI”.
2. Audit не имеет права получать unredacted PII/secrets.
3. Если безопасная обработка невозможна, приоритет у `drop`/`gap event`, а не у записи сырого значения.
4. Rule execution должна быть детерминированной и повторяемой в replay/debug path.

## Критерий актуальности

Документ считается актуальным только если:
- перечислены источники, где применяется redaction;
- определены `rule_id` и `field_paths`;
- явно указано, что redaction идёт ДО записи в AuditEntry и ДО выдачи наружу (UI/API);
- есть раздел `configurable rules` с хранением, versioning, rollout/rollback;
- определён event `privacy.redaction_applied`;
- определён failure-mode `observability_gap.redaction_failed`.
