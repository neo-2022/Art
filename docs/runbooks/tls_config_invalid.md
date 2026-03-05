# Runbook: tls_config_invalid

## mitigations
- проверить cert/key пару
- проверить права на файлы
- выполнить rollback последнего cert

## verification
- health=ok
- stream доступен
- gap событие закрыто
