# Art v1: 100% observability platform

Документ и код нового репозитория Art основаны на спецификации `Art_v1_spec_final.md` и `REGART -  LangGraph  взаимодействие с Art описание` из `/home/art/Документы/Art`.

## Цели
1. Реализовать архитектуру Art v1: Core (Rust), Agent (Rust), Browser Level0 (JS). Core обеспечивает ingest/snapshot/stream/incidents, Agent собирает journald/systemd/net/OTLP и доставляет RawEvent, а Browser Level0 отправляет события из REGART.
2. Обеспечить контракт ingest/stream (POST `/api/v1/ingest`, GET `/api/v1/stream`, etc.) с надежной семантикой ack/seq/dedup/backpressure и spool/outbox.
3. Создать onboarding-документацию для интеграции `REGART` (my_langgraph_agent) через UI Proxy и Level0, включая мост Level0→Art Agent и Rich Errors, как описано в `REGART - ... описание`.

## Структура репозитория
- `core/` — Rust-бинарник Art Core (ingest/pipeline/snapshot/stream). Пока шаблонное описание, позже добавим реализацию.
- `agent/` — Rust Agent/Sidecar (journald/systemd, ports, spool/outbox). Содержит спецификации receivers, spool, delivery semantics.
- `browser/` — JavaScript Level0/Level1 bridge, следующий за спецификацией Browser Level0.
- `docs/` — спецификации контрактов, runbooks, integration guides (ссылки на `REGART - ... описание`).
- `scripts/` — утилиты для генерации RawEvent/backup и тестирования.

## Следующие шаги
1. В `core/` описать API Contract и поступающие RawEvent/Incident flow; подготовить mocks и SQL (как описано в `Art_v1_spec_final.md` разделы 5-10).
2. В `agent/` реализовать сборщики journald/systemd и OTLP, а также `spool/outbox` с гарантией `never_drop_unacked` (раздел 7 спецификации).
3. В `browser/` описать мост между Level0 и Art Agent, включая backlog (IndexedDB) и отправку RawEvent с `observability_gap.*` (раздел 3.3 и 6).
4. Подготовить интеграцию с REGART: инструкции по проксированию `/ui/art/stream`, форворду ошибок из UI Proxy и методы инспекции, описанные в `REGART - ... описание`.
5. Описать процесс тестирования (pytest/rs tests) и CI (через GitHub Actions). 

Документы `Art_v1_spec_final.md` и `REGART -  LangGraph  взаимодействие с Art описание` следует держать рядом для детализации архитектуры и требований к интеграции.
