# Art v1 architecture overview

Исходя из `Art_v1_spec_final.md` и `REGART -  LangGraph  взаимодействие с Art описание`:

- **Core (Rust)**: ingest → pipeline → incidents → snapshot/stream. В текущем этапе описывается API (POST `/api/v1/ingest`, GET `/api/v1/stream`, GET `/api/v1/snapshot`, Health, Metrics) и структура Storage (SQLite v1, уникальность incident_key, fingerprint collision handling, action lifecycle).
- **Agent (Rust)**: systemd/journald/ports/OTLP collectors, outbox/spool (never_drop_unacked), delivery semantics (ack.upto_seq, dedupe). В ближайшем шаге нужно подготовить описание каждого receiver и его observability_gap бывают.
- **Browser Level0/Level1**: отправка runtime ошибок и UX-событий через IndexedDB backlog, bridging for `REGART` (Level0 = источник, React UI = экран). Мост должен обеспечивать сохранение RawEvent при недоступном Art, требование `observability_gap.*` при потере канала.
- **Integration plan with REGART**: UI Proxy (FastAPI) должен писать Rich Errors и проксировать `/ui/art/stream`, React Level0 должен отправлять события через Art Agent. Документ `REGART -...` перечисляет шаги: запуск Art до REGART, каналы A/B/C, dedupe, snapshot, correlation.

Дополнительно `docs/CONTRACTS.md` будет содержать JSON schema/ack semantics, `docs/INTEGRATION.md` — план интеграции с my_langgraph_agent.
