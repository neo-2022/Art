# REGART ↔ Art integration tasks

Цель: REGART (my_langgraph_agent) снабжает Art v1 всеми RawEvent/Incidents, а Art поддерживает панель 0 и мост ошибок.

## Key touchpoints
1. **UI Proxy**: подключить `ART_STREAM_URL` к `/ui/art/stream`, добавить Rich Errors по upstream и проксировать `/ui/art/ingest`/`/ui/art/stream`. Поддерживать retries/cursor/Retry-After (см. `agent/tests/integration_tests/*`).
2. **Browser Level0**: полная коллекция событий (errors/events/network/snapshots). При недоступности Art записывать `observability_gap.*` и синхронизировать после восстановления.
3. **Graph/Inspector**: nodeStart/nodeEnd events должны поступать в Level0 и пробрасываться как RawEvent (`payload.short_result`, `metadata`).
4. **Run journal**: события `run`, `edge_chosen`, `tool_call` должны отправляться через Art Agent ingest. Обязательно correlation span_id/node_id.

## Next actions
- [ ] Создать прототип Art Core ingest API (FastAPI/Rust), отдающий SSE `stream` и snapshot/health.
- [ ] Определить schema RawEvent для `node_start`/`node_end`/`tool_*` и `observability_gap.*` для LOST events.
- [ ] Организовать backlog (IndexedDB) в Browser Level0 и документацию `obs/outbox` (пример: `scripts/mock_art_stream.py`).
- [ ] Синхронизировать с `run.sh`/systemd: Art Agent и REGART сервисы управляются systemd user services.
