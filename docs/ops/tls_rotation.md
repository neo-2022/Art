# TLS rotation

1. Обновить cert/key.
2. `systemctl kill -s SIGHUP art-core.service`.
3. Проверить, что stream (`/api/v1/stream`) не разорван.

Smoke:
- держим stream подключенным
- меняем сертификат
- отправляем SIGHUP
- stream активен

pass/fail: pass
