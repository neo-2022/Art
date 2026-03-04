# Art v1 — платформа 100% наблюдаемости (Observability)

Art v1 — платформа наблюдаемости с жёсткими контрактами событий и управляемой деградацией: **Core (Rust)**, **Agent (Rust)**, **Browser Level0 (JS)** и **Packs**.

Репозиторий ведётся **docs-first**: сначала фиксируются требования/контракты/чек-листы, затем по ним добавляется реализация.

## Source of Truth
- Мастер-спецификация: `docs/source/Art_v1_spec_final.md`
- Интеграция REGART ↔ Art: `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Чек-листы (00..26): `docs/source/checklists/`

## Архитектура (кратко)
- **Core (Rust)** — ingest/pipeline/snapshot/stream (SSE)/incidents/actions/audit.
- **Agent (Rust)** — receivers (journald/file/process/OTLP), spool/outbox, доставка в Core с backpressure/ack/seq.
- **Browser Level0 (JS)** — локальная очередь (IndexedDB), multi-tab дедуп, доставка событий из браузера/REGART.
- **Packs** — расширения (rules/enrich/fixtures), установка вручную с подписью и проверкой совместимости.

## Структура репозитория
- `core/` — Art Core (Rust)
- `agent/` — Art Agent (Rust)
- `browser/` — Browser Level0 (JS)
- `docs/` — документация, контракты, runbooks
- `scripts/` — утилиты и CI-gates

## Навигация
- Главный индекс документации: `docs/README.md`
- Старт: `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- Контракты/схемы и codegen: см. чек-лист 08 в `docs/source/checklists/`
- CI/безопасность поставок (supply-chain): см. чек-лист 04 в `docs/source/checklists/`

## Текущее состояние
- В репозитории уже загружены спецификации и полный набор чек-листов.
- Реализация будет добавляться этапами строго по чек-листам, начиная с контрактов/схем/ingest.

## Безопасность
Правила репорта уязвимостей: `SECURITY.md`.

## Лицензия
Лицензия будет зафиксирована перед публичным релизом.
