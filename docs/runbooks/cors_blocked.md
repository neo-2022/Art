# Runbook: cors_blocked

## mitigations
1. Проверить CORS allowlist в ingest/proxy для текущего `browser_origin`.
2. Проверить preflight (`OPTIONS`) и заголовки `Access-Control-Allow-*`.
3. Убедиться, что endpoint из события доступен и не переадресует на чужой origin.
4. При необходимости временно включить разрешённый origin для восстановления трафика.

## verification
1. В snapshot/stream появляется событие `observability_gap.cors_blocked` с полями:
   `endpoint`, `browser_origin`, `block_type`, `retry_count`, `trace_id`.
2. После исправления новые события `observability_gap.cors_blocked` не появляются.
3. Интеграционный тест `browser/test/multitab.e2e.test.js` проходит.
