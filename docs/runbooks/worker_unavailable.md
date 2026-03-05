# Runbook: worker_unavailable

## mitigations
1. Проверить поддержку Worker API в целевом браузере/окружении.
2. Проверить CSP/политику безопасности, блокирующую worker.
3. Убедиться, что main-thread fallback включился и продолжает flush/cleanup/compress.
4. Восстановить worker path и снять деградацию.

## verification
1. В snapshot/stream есть `observability_gap.worker_unavailable`.
2. В evidence есть `reason`, `browser_details`, `trace_id`.
3. В режиме fallback операции enqueue/flush/cleanup выполняются успешно.
