# TLS rotation

1. Обновить cert/key.
2. `systemctl restart art-core.service`.
3. Проверить, что stream (`/api/v1/stream`) поднимается с новым сертификатом.

Smoke:
- меняем сертификат
- рестартуем core
- проверяем `curl -vk https://127.0.0.1:7331/health`
- проверяем stream-подключение

pass/fail: pass

Runtime smoke в CI выполняется скриптом `scripts/tests/ops_stage23_smoke.sh`:
- проверяет ingest -> snapshot после DR restore smoke;
- проверяет, что после `SIGHUP` runtime-hook Core и stream-соединение остаются активными.
