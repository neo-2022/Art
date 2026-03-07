# Regional profiles

Этот документ фиксирует региональные профили Art как детерминированные наборы параметров.
Запрещены сокращения через ссылки на другой профиль, скрытое наследование от `global`
и любые непрямые значения. Каждый профиль задаётся здесь полным явным набором значений.

## profile: global
- profile_id: global
- storage_class: primary
- storage_data_residency: any
- storage_allowed_regions: ["global"]
- storage_replication_mode: geo-redundant
- retention_days_events: 30
- retention_days_incidents: 90
- retention_days_audit: 365
- dsr_mode: supported
- export_mode: standard
- export_allowed_targets: ["approved-external", "customer-managed-bucket", "local-file"]
- export_cross_border: allowed-with-policy
- egress_policy: controlled
- egress_allowed_destinations: ["approved-api", "approved-object-store", "approved-alerting"]
- egress_default_action: deny
- updates_mode: online
- updates_source: signed-online-repository
- packs_install_mode: signed-online
- telemetry_mode: full
- telemetry_external_export: allowed
- logging_mode: full
- logging_payload_policy: redacted

## profile: eu
- profile_id: eu
- storage_class: primary
- storage_data_residency: eu-only
- storage_allowed_regions: ["eu"]
- storage_replication_mode: eu-internal-only
- retention_days_events: 30
- retention_days_incidents: 90
- retention_days_audit: 365
- dsr_mode: mandatory
- export_mode: restricted
- export_allowed_targets: ["eu-approved-target", "local-file"]
- export_cross_border: denied
- egress_policy: strict
- egress_allowed_destinations: ["eu-approved-api", "eu-approved-alerting"]
- egress_default_action: deny
- updates_mode: controlled
- updates_source: signed-eu-repository
- packs_install_mode: signed-controlled
- telemetry_mode: restricted
- telemetry_external_export: eu-only
- logging_mode: restricted
- logging_payload_policy: redacted

## profile: ru
- profile_id: ru
- storage_class: primary
- storage_data_residency: ru-only
- storage_allowed_regions: ["ru"]
- storage_replication_mode: ru-internal-only
- retention_days_events: 30
- retention_days_incidents: 90
- retention_days_audit: 365
- dsr_mode: regulated
- export_mode: restricted
- export_allowed_targets: ["ru-approved-target", "local-file"]
- export_cross_border: denied
- egress_policy: strict
- egress_allowed_destinations: ["ru-approved-api", "ru-approved-alerting", "ru-approved-update-gateway"]
- egress_default_action: deny
- updates_mode: controlled
- updates_source: signed-ru-repository
- packs_install_mode: signed-controlled
- telemetry_mode: restricted
- telemetry_external_export: ru-only
- logging_mode: restricted
- logging_payload_policy: redacted

## profile: airgapped
- profile_id: airgapped
- storage_class: isolated-local
- storage_data_residency: local-only
- storage_allowed_regions: ["local-segment"]
- storage_replication_mode: manual-approved-only
- retention_days_events: 30
- retention_days_incidents: 90
- retention_days_audit: 365
- dsr_mode: manual-controlled
- export_mode: offline-only
- export_allowed_targets: ["approved-offline-media"]
- export_cross_border: denied
- egress_policy: blocked
- egress_allowed_destinations: []
- egress_default_action: deny
- updates_mode: manual-offline
- updates_source: signed-offline-bundle
- packs_install_mode: signed-offline-manual
- telemetry_mode: local-only
- telemetry_external_export: denied
- logging_mode: local-only
- logging_payload_policy: redacted

## profile selection
- Конфиг-поле: `profile_id`
- Файл конфига Core: `config/core.toml` (можно переопределить через `CORE_CONFIG_PATH`)
- Автодетект профиля запрещён
- Допустимые значения `profile_id`: `global|eu|ru|airgapped`
- Любое другое значение `profile_id` блокирует startup и `POST /api/v1/profile/apply`
- `effective_profile_id` вычисляется детерминированно по правилу:
  1. прочитать `profile_id` из активного конфига Core;
  2. проверить значение на принадлежность фиксированному enum `global|eu|ru|airgapped`;
  3. при успешной валидации принять это значение как `effective_profile_id`;
  4. при неуспешной валидации завершить запуск или отклонить apply-config без fallback.
- Никаких fallback-правил, environment autodetect и silent default не допускается
- `effective_profile_id` логируется без PII в startup/runtime log как `effective_profile_id=<value>`
- Диагностика через API: `GET /api/v1/profile` возвращает поле `effective_profile_id`
- Диагностика через метрику: `art_core_effective_profile_info{effective_profile_id=\"<value>\"} 1`
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
