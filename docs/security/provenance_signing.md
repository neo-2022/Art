# Provenance and signing policy

Инструмент: cosign.
Режим: keyless OIDC в GitHub Actions.
Подписываемые артефакты:
- agent/dist/*
- ui/dist/*
- sbom.spdx.json
- checksums.txt

Verify подписи обязателен в релизном CI.
Подписи и attestations публикуются вместе с релизными артефактами.
