# Runbook: release_signing_failed

## mitigations
- проверить cosign ключи/identity
- пересобрать артефакт
- повторить verify

## verification
- cosign verify успешно
- release job зеленый
