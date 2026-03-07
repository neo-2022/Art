# Packs spec v1

## Layout
- `manifest.yaml`
- `payload/`
- `signatures/`

## `manifest.yaml` (обязательные поля)
- `name` (string, уникальный)
- `version` (SemVer)
- `dependencies` (обязательно): `[{name: string, version_range: string}]`
- `entrypoints` (обязательно): список строк
- `service_inventory` (обязательно): список внешних систем/компонентов, которые pack вводит в контур Art
- `receiver_examples` (обязательно): какие receiver kinds используются для этой системы
- `signal_coverage_claims` (обязательно): какие типы данных обещаны и какие ожидаются как observed
- `telemetry_endpoints` (обязательно): точки передачи сигналов в Art
- `regulatory_tags` (обязательно): специальные режимы/ограничения интеграции
- `connected_system_projection` (обязательно): как система должна появиться в Connected System View

## `signatures/`
- cosign signature
- attestation (если применяется политикой поставки)

## Связь с Connected System View
Pack считается неполным, если после его установки оператор не может понять:
- какая именно система подключена;
- какие данные она обещает отдавать;
- какие данные Art реально уже наблюдает;
- есть ли coverage drift.

Поэтому `connected_system_projection` обязан содержать минимум:
- `system_id`
- `display_name`
- `integration_kind`
- `declared_data_kinds`
- `connection_status` semantics
