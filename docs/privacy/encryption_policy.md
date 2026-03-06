# Encryption policy

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/retention_matrix.md`
- `docs/ops/platform-support.md`

## In-transit

TLS обязателен in-transit.

Это означает:
- внешние network hops к Core идут только через TLS-защищённый transport path;
- agent/bridge/export paths не должны использовать plaintext transport в production profile;
- downgrade до plaintext не допускается как hidden fallback.

## Encryption-at-rest

Encryption-at-rest обязателен для:
- `events`
- `audit`
- `attachments`

Дополнительно baseline применяется к:
- локальным persistent privacy-sensitive blobs
- profile-specific offline/export bundles, если они содержат PII или чувствительные артефакты

## По типам хранилищ

| Тип данных | Требование |
|---|---|
| `events` | encryption-at-rest обязателен |
| `audit` | encryption-at-rest обязателен |
| `attachments` | encryption-at-rest обязателен |

## Key rotation

Baseline key rotation:
- каждые `90 days`

Ответственный компонент:
- `security/platform`

Жёсткое правило:
- rotation должна быть плановой и auditable;
- emergency rotation допустима вне расписания;
- смена ключей не должна приводить к молчаливой потере доступа без documented recovery path.

## Критерий актуальности

Документ считается актуальным только если:
- TLS in-transit зафиксирован явно;
- encryption-at-rest зафиксирован по каждому типу данных из baseline;
- период key rotation указан числом;
- указан ответственный компонент.
