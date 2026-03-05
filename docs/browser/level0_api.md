# Browser Level0 API

- multi-tab leader election обязателен
- delivery dedup key обязателен
- worker path primary, main-thread fallback secondary

Multi-tab protocol:
- `tab_id` генерируется как UUIDv4 и хранится в `sessionStorage` (только текущая вкладка).
- lock лидера хранится в `localStorage` по ключу `art:l0:leader`.
- лидер пишет heartbeat `{"tab_id":"...","ts_ms":...}` каждые 1000 мс.
- lock считается устаревшим, если `ts_ms` старше 3000 мс.
- только лидер выполняет flush в ingest.
- локальные события публикуются в `BroadcastChannel` `art:l0:events`.
- dedup key: `sha256(canonical_json(normalized_event))`.
- `canonical_json` использует сортировку ключей и удаляет поля `ts_ms`.
