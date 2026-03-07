# Политика Provenance И Подписей

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/release_stage04.yml`
- `docs/release/release_process.md`
- `docs/security/release_hardening.md`

## Назначение
Этот документ фиксирует production-baseline для подписи и provenance релизных артефактов Art. Политика обязательная: release считается недействительным, если подписи, verify или provenance нарушены.

## Инструмент и режим
- инструмент подписи: `cosign`
- режим подписи: `keyless OIDC` через GitHub Actions
- verify выполняется по certificate identity и OIDC issuer, а не через локальный placeholder public key

## Что подписывается
Подписываются все релизные артефакты фиксированного набора. Минимальный обязательный перечень:
- `agent/dist/*`
- `ui/dist/*`
- `sbom.spdx.json`
- `checksums.txt`
- `provenance.attestation.json`

Дополнительно production baseline требует подписи бинарных release artifacts из `core/dist/*`. Отсутствие подписи `core/dist/*` считается supply-chain regression, даже если минимальный перечень выше формально выполнен.

## Обязательные release артефакты
Каждый релиз обязан публиковать:
- release artifacts из:
  - `core/dist/*`
  - `agent/dist/*`
  - `ui/dist/*`
- `sbom.spdx.json`
- `checksums.txt`
- `provenance.attestation.json`
- для каждого подписанного файла:
  - `.sig`
  - `.pem`

## Требования к provenance
- provenance должен содержать:
  - `repository`
  - `ref`
  - `sha`
  - `run_id`
  - `run_attempt`
  - `generated_at_utc`
  - список `subjects` с `sha256` как минимум для:
    - `core/dist/*`
    - `agent/dist/*`
    - `ui/dist/*`
    - `sbom.spdx.json`
    - `checksums.txt`
- provenance обязан проверяться в release CI как отдельный шаг;
- provenance без корректного соответствия текущему `sha/run` считается провалом релиза.

## Требования к verify
- verify обязателен в release CI;
- verify обязан использовать:
  - `--certificate-oidc-issuer https://token.actions.githubusercontent.com`
  - `--certificate-identity-regexp` с привязкой к workflow `release_stage04.yml`
- публикация без успешного verify запрещена;
- локальная ручная публикация без этого verify запрещена.

## Air-gapped и offline verify
Для offline и air-gapped сценариев baseline опирается не на файл `cosign.pub`, а на detached certificate и identity-based verification.

Допустимый контур:
1. получить из релиза:
   - артефакт
   - `.sig`
   - `.pem`
   - `checksums.txt`
   - `provenance.attestation.json`
2. проверить checksum;
3. выполнить `cosign verify-blob` по `certificate + signature + issuer + identity regexp`;
4. сверить `sha` и `subjects` из provenance.

## Что считается провалом
- нет `checksums.txt`;
- нет `provenance.attestation.json`;
- нет `.sig` или `.pem`;
- verify не проходит;
- provenance не соответствует `repository/ref/sha/run`;
- в документации или release flow используется placeholder key material.

## Запрещено
- placeholder public key в production baseline;
- release без `.pem` certificate bundle;
- release без `checksums.txt`;
- release без verify;
- release с несогласованными списками артефактов между policy и workflow.
