# Signing Keys Baseline

## Source of truth
- `docs/security/provenance_signing.md`
- `.github/workflows/release_stage04.yml`

## Политика
Для production baseline Art не хранит в репозитории placeholder public key для релизной подписи.

Релизная подпись выполняется в режиме `cosign keyless OIDC`, а verify строится на:
- detached signature;
- detached certificate (`.pem`);
- OIDC issuer;
- certificate identity regexp;
- provenance attestation.

## Запрещено
- добавлять фиктивный `cosign.pub`;
- использовать placeholder key material как доказательство production signing readiness.
