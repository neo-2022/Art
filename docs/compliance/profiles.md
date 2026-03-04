# Regional profiles

## profile: global
- storage_class: primary
- storage_data_residency: any
- retention_days: 30
- export_mode: standard
- egress_policy: controlled
- updates_mode: online
- telemetry_mode: full

## profile: eu
- storage_class: primary
- storage_data_residency: eu-only
- retention_days: 30
- export_mode: restricted
- egress_policy: strict
- updates_mode: controlled
- telemetry_mode: restricted

## profile: ru
- storage_class: primary
- storage_data_residency: ru-only
- retention_days: 30
- export_mode: restricted
- egress_policy: strict
- updates_mode: controlled
- telemetry_mode: restricted

## profile: airgapped
- storage_class: isolated-local
- storage_data_residency: local-only
- retention_days: 30
- export_mode: offline-only
- egress_policy: blocked
- updates_mode: manual-offline
- telemetry_mode: local-only

## profile selection
- Конфиг-поле: `profile_id`
- Файл конфига Core: `config/core.toml` (можно переопределить через `CORE_CONFIG_PATH`)
- Автодетект профиля запрещён
- `effective_profile_id` вычисляется детерминированно из `profile_id`
- `effective_profile_id` логируется без PII
- Диагностика: API поле `effective_profile_id`
- Runtime apply: `POST /api/v1/profile/apply` (на нарушении guardrails профиль не применяется)

## profile switch procedure
1. stop ingest
2. stop core
3. apply new config (`profile_id`)
4. start core
5. run profile guards
6. start ingest

## migration/validation
- Переходы требуют validate/migrate/purge/reindex по матрице

## transition matrix
| from | to | actions | allowed |
|---|---|---|---|
| global | eu | validate + reindex | yes |
| global | ru | validate + reindex | yes |
| global | airgapped | migrate + validate + purge remote | yes |
| eu | ru | validate residency + reindex | yes |
| ru | eu | export compliance check | no |
| airgapped | global | manual export review | no |

## privacy linkage
- Различия retention/DSR синхронизируются с `docs/privacy/regional_profiles.md`.
- Конфликт правил -> `observability_gap.profile_violation`.
