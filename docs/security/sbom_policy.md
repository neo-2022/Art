# SBOM policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/release_stage04.yml`
- `docs/security/provenance_signing.md`

## Инструмент и формат
- единый инструмент генерации SBOM: `syft`
- обязательный формат SBOM: `SPDX JSON`
- canonical filename: `sbom.spdx.json`

## Release baseline
- SBOM генерируется для каждого релиза
- SBOM прикладывается к релизным артефактам как отдельный release asset
- SBOM включается в `checksums.txt`
- SBOM включается в signed/provenance bundle релиза

## Scope
- SBOM обязан описывать release artifacts production baseline
- release без `sbom.spdx.json` считается неполным
- локальная ручная генерация SBOM не заменяет CI-generated release SBOM

## Enforcement
- SBOM генерируется только в release CI path
- отсутствие `sbom.spdx.json` или нарушение формата `SPDX JSON` блокирует release
