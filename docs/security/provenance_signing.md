# Политика Provenance И Подписей

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/release/release_process.md`
- `docs/security/release_hardening.md`

## Инструмент И Режим
- инструмент подписи: `cosign`
- режим: `keyless OIDC` в GitHub Actions

## Что Подписывается
- release artifacts
- SBOM
- checksum-файлы
- provenance attestation

Технические идентификаторы релизного контура:
- `agent/dist/*`
- `ui/dist/*`
- `sbom.spdx.json`
- `checksums.txt`
- `provenance.attestation.json`

## Требования
- verify подписи обязателен в release CI
- provenance должен содержать привязку к repository/ref/sha/run_id
- subjects должны быть перечислены с SHA256
- подписи и attestation публикуются вместе с релизными артефактами

## Что Считается Провалом
- нет verify-подтверждения
- provenance не соответствует релизному commit/run
- подписи не приложены к релизной поставке
