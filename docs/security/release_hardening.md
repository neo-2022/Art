# Release hardening

- Локальные релизы запрещены.
- Релиз создаётся только из CI workflow.
- Источник: защищённый тег.
- Тег релиза создаётся через PR/CI процедуру.
- Перед публикацией обязательны зелёные security jobs.
- Перед публикацией обязательны: генерация SBOM, checksums, provenance attestation и verify подписи cosign.
