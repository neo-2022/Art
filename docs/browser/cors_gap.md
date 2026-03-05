# CORS gap

При блокировке CORS в `Level0MultiTabCoordinator` генерируется событие
`observability_gap.cors_blocked`, которое отправляется в snapshot/stream через
gap-эмиттер (`emitGapFn`).

## Формат события
- `kind`: `observability_gap.cors_blocked`
- `trace_id`: UUIDv4
- `what`: причина на уровне продукта
- `where`: `browser.level0.ingest`
- `why`: `cors_blocked`
- `evidence`:
  - `endpoint`
  - `browser_origin`
  - `block_type`
  - `retry_count`
  - `error_message`
- `actions`: ссылка на `docs/runbooks/cors_blocked.md`
