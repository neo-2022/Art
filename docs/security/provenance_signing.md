# Provenance and signing policy

Инструмент: cosign.
Режим: keyless OIDC в GitHub Actions.
Подписываемые артефакты:
- agent/dist/*
- ui/dist/*
- sbom.spdx.json
- checksums.txt
- provenance.attestation.json

Verify подписи обязателен в релизном CI.
Аттестация provenance формируется как `provenance.attestation.json` и содержит:
- repository/ref/sha/run_id/run_attempt
- subjects с SHA256 для `agent/dist/*`, `ui/dist/*`, `sbom.spdx.json`, `checksums.txt`

Подписи и attestations публикуются вместе с релизными артефактами и проверяются в release workflow.
