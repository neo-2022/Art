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

Runtime smoke в CI выполняется скриптом `scripts/tests/ops_stage23_smoke.sh`:
- проверяет ingest -> snapshot после DR restore smoke;
- проверяет, что после `SIGHUP` процесс Core и stream-соединение остаются активными.
