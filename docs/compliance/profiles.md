# Regional profiles

## profile: global
- retention_days: 30
- export_mode: standard
- egress_policy: controlled
- residency: any
- updates_mode: online

## profile: eu
- retention_days: 30
- export_mode: restricted
- egress_policy: strict
- residency: eu-only
- updates_mode: controlled

## profile: ru
- retention_days: 30
- export_mode: restricted
- egress_policy: strict
- residency: ru-only
- updates_mode: controlled

## profile: airgapped
- retention_days: 30
- export_mode: offline-only
- egress_policy: blocked
- residency: local-only
- updates_mode: manual-offline

## profile selection
- Конфиг-поле: `profile_id`
- Файл конфига Core: `config/core.toml` (можно переопределить через `CORE_CONFIG_PATH`)
- Автодетект профиля запрещён
- `effective_profile_id` вычисляется детерминированно из `profile_id`
- `effective_profile_id` логируется без PII
- Диагностика: API поле `effective_profile_id`

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
