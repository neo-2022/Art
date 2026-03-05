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

Outbox runtime:
- compression threshold: `1024` bytes (`gzip` if payload is larger).
- outbox TTL: `7 суток` (`604800000` ms) -> move to DLQ.
- DLQ retention: `30 суток` (`2592000000` ms) -> hard delete.
- cleanup starts on init and then each `300000` ms.
- overflow policies:
  - `never_drop_unacked`: reject new + `observability_gap.outbox_full`.
  - `drop_oldest_when_full`: drop oldest + `data_quality.lossy_outbox_drop` + `incident.lossy_mode_active` (SEV1).

Worker/fallback:
- operations `enqueue`, `flushAll`, `cleanup` go through worker-first executor.
- when worker path is unavailable, main-thread fallback remains functional.
- fallback always emits `observability_gap.worker_unavailable`.
