# Классификация данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/privacy/redaction_policy.md`
- `docs/privacy/retention_matrix.md`

## Назначение

Этот документ фиксирует каноническую классификацию данных для Art.
Классификация обязательна для:
- `Art Core`
- `Art Agent`
- `Browser Level0`
- `Panel0`
- `Art Console`
- audit trail
- attachments
- export/compliance path

Ни один компонент не имеет права записывать, индексировать, экспортировать или показывать данные без привязки к одной из категорий ниже.

## Канонические категории

### 1. `PII`

Персональные или квазиперсональные данные, позволяющие прямо или косвенно идентифицировать человека.

Типовые примеры:
- email
- username / login
- display name
- phone number
- IP address
- session identifier
- user id / external id / customer id
- employee id
- device id, если он связан с конкретным пользователем
- browser fingerprint / client fingerprint, если он используется как идентификатор человека

Подкатегории:
- `direct_pii`: имя, email, телефон, явный user id
- `indirect_pii`: IP, device id, internal/external correlation id, если по ним можно восстановить человека
- `sensitive_pii`: данные, которые в конкретной среде дают повышенный риск (например, patient id, passport-like identifiers, financial customer keys)

Базовое правило:
- `PII` по умолчанию не должна попадать в UI, индекс, audit и attachments без policy-driven redaction и role-based доступа.

## 2. `secrets`

Данные, компрометация которых даёт несанкционированный доступ, позволяет выполнять действия или раскрывает доверенный контур.

Типовые примеры:
- API keys
- bearer tokens
- JWT
- cookies
- refresh tokens
- session tokens
- client secrets
- private keys
- SSH keys
- DB passwords
- auth headers
- proxy credentials
- webhook secrets

Подкатегории:
- `auth_secret`
- `transport_secret`
- `storage_secret`
- `integration_secret`

Базовое правило:
- `secrets` не должны храниться в явном виде ни в событиях, ни в audit, ни в индексах, ни во вложениях метаданных.
- Для `secrets` default action = `redact` или `drop`.

## 3. `telemetry`

Технические сигналы, необходимые для диагностики состояния систем, но не являющиеся сами по себе business-data payload.

Типовые примеры:
- severity
- timestamp
- service name
- component name
- host name
- pod name
- process state
- queue lag
- retry count
- event size
- latency values
- error class
- transport status

Подкатегории:
- `metrics_like`
- `logs_like`
- `trace_like`
- `health_signal`

Базовое правило:
- `telemetry` разрешена к хранению и анализу, если она не содержит встроенные `PII` или `secrets`.
- Если telemetry payload смешан с `PII` или `secrets`, сначала применяется redaction/minimization, и только после этого данные могут считаться telemetry-safe.

## 4. `operational`

Данные о конфигурации, topology, политике, жизненном цикле действий и внутреннем устройстве системы.

Типовые примеры:
- build id
- profile id
- config version
- rule id
- rollout state
- incident id
- dna id
- audit id
- feature flag state
- storage backend state
- spool health
- receiver kind
- policy decision metadata

Подкатегории:
- `runtime_operational`
- `governance_operational`
- `deployment_operational`

Базовое правило:
- `operational` данные можно хранить и показывать, если они не содержат `PII`/`secrets`.
- Если operational metadata связывается с человеком, она автоматически пересматривается на предмет `indirect_pii`.

## 5. `attachments`

Любое бинарное или полуструктурированное вложение, которое может быть связано с incident, evidence, action result или audit trail.

Типовые примеры:
- log dump
- screenshot
- PDF export
- CSV export
- zipped evidence bundle
- replay capsule
- stack trace file
- HAR/network capture

### Attachments как потенциальная PII

Каждое вложение считается потенциально чувствительным до явной классификации.

Почему:
- screenshot может содержать email, имена, внутренние IDs;
- PDF может содержать персональные или финансовые данные;
- CSV и HAR часто содержат cookies, headers, query params, identifiers;
- archive может включать stack traces, credentials, tokens или raw payloads.

Обязательное правило:
- `attachments` нельзя считать “безопасными по умолчанию”;
- любой attachment проходит:
  - MIME/payload validation
  - sensitivity classification
  - retention assignment
  - access scope assignment
  - redaction / sanitization, если это применимо

## Матрица примеров по контурам Art

| Контур | Пример данных | Категория |
|---|---|---|
| Agent receiver | `Authorization: Bearer ...` | `secrets` |
| Agent receiver | `systemd unit failed` | `telemetry` |
| Browser Level0 | browser error с user email в message | `PII` + `telemetry` |
| Core ingest | `trace_id`, `receiver_kind`, `source_seq` | `operational` |
| Audit trail | `actor`, `target`, `result`, `evidence_ref` | `operational`, а `actor` пересматривается на `PII` |
| Evidence attachment | screenshot UI with customer name | `attachments` + `PII` |
| InvestigationDoc | human decision text with copied token | `secrets` |

## Правила при смешанных данных

Если объект содержит несколько категорий:
- применяется наиболее строгий privacy regime;
- `secrets` имеют приоритет над `PII`;
- `PII` имеют приоритет над чистой `telemetry`;
- `attachments` рассматриваются как контейнер, который может содержать любую из категорий и потому проходит отдельную оценку.

Примеры:
- лог содержит IP и токен -> классификация: `secrets + PII`
- screenshot содержит имя и internal host status -> `attachments + PII + operational`
- audit actor записан как email -> `PII`, а не просто `operational`

## Запрещённые упрощения

Запрещено:
- считать IP всегда “не PII”;
- считать internal ids всегда “безопасными”;
- считать attachments “только файлами” без privacy-анализа;
- считать telemetry автоматически безопасной без проверки на embedded secrets/PII.

## Результат классификации

Категория данных определяет:
- redaction policy
- access scope
- retention policy
- export policy
- audit handling
- indexing allowance
- UI rendering constraints

## Критерий актуальности

Документ считается актуальным только если:
- перечислены канонические категории;
- приведены конкретные примеры `PII`, `secrets`, `telemetry`, `operational`, `attachments`;
- есть отдельный раздел `Attachments как потенциальная PII`;
- правила применимы к Agent/Core/Console/Audit/Attachments без двусмысленности.
