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

## `signatures/`
- cosign signature
- attestation (если применяется политикой поставки)
