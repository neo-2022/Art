# Art v1 Architecture

Документ синхронизирован с:
- `docs/source/Art_v1_spec_final.md`
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`

## 1. Принципы v1

1. `100% observability` по доступным сигналам (включая фиксирование `observability_gap.*`).
2. `UI как экран`: источник правды в Core pipeline и инцидентах.
3. `Store-and-forward`: ни один event не теряется без явного события о потере.

## 2. Компоненты и границы ответственности

### 2.1 Art Core (Rust)

- Приём: `POST /api/v1/ingest`
- Чтение: `GET /api/v1/snapshot`, `GET /api/v1/stream`, `GET /api/v1/incidents`
- Управление: `POST /api/v1/incidents/{id}/ack`, `.../resolve`, `POST /api/v1/actions/execute`
- Служебное: `GET /health`, `GET /metrics`
- Pipeline: `parse -> validate -> quality gates -> fingerprint -> rules -> aggregate -> incident -> enrich -> store -> publish`
- Storage v1: SQLite WAL, миграции, retention, уникальность `incident_key = rule.id + fingerprint`

### 2.2 Art Agent (Rust)

- Receivers: journald, systemd, files, proc, ports, net_probe, OTLP
- Надёжная доставка: spool/outbox (`write -> send -> ack -> delete confirmed`)
- Режим по умолчанию: `never_drop_unacked`
- При деградации: явные события `data_quality.*` и/или `observability_gap.*`

### 2.3 Browser Level0 (JS)

- Сбор ошибок runtime и UX-событий.
- Локальный backlog (IndexedDB) для offline/temporary failures.
- Отправка в Art Agent/Core с корреляцией, когда доступна.
- При невозможности доставки: события о gap, а не молчаливая потеря.

## 3. Модель интеграции с REGART

В интеграции с REGART используются три канала:
- `A (OS-level)` — через Agent (systemd/journald/ports/net probes)
- `B (backend-level)` — события сервисов REGART (UI Proxy, LangGraph)
- `C (browser-level)` — события из REGART Level0

Ключевой порядок запуска:
1. Art Core
2. Art Agent
3. REGART services

Так обеспечивается диагностика даже если REGART не поднялся.

## 4. Нормативная трассировка в документах

- Полный норматив: `docs/source/Art_v1_spec_final.md`
- Конкретно по REGART: `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Поэтапная реализация: `docs/source/checklists/README.md`
- Рабочий план интеграции: `docs/INTEGRATION.md`
