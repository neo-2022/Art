# Art v1 — платформа 100% наблюдаемости (Observability)

Art v1 — платформа наблюдаемости с жёсткими контрактами событий и управляемой деградацией: **Core (Rust)**, **Agent (Rust)**, **Browser Level0 (JS)** и **Packs**.

Репозиторий ведётся **docs-first**: сначала фиксируются требования/контракты/чек-листы, затем по ним добавляется реализация.

## Source of Truth
- Мастер-спецификация: `docs/source/Art_v1_spec_final.md`
- Интеграция REGART ↔ Art: `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Foundation v0.2 (monorepo/Tier A+B+C): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- DNA determinism/performance standard: `docs/source/dna_core_determinism_performance_assurance.md`
- Risk register v0.2: `docs/source/risk_register_v0_2.md`
- Analytics memory spec: `docs/source/analytics_memory_v0_2.md`
- Чек-листы (00..38): `docs/source/checklists/`

## Архитектура (кратко)
- **Core (Rust)** — ingest/pipeline/snapshot/stream (SSE)/incidents/actions/audit.
- **Agent (Rust)** — receivers (journald/file/process/OTLP), spool/outbox, доставка в Core с backpressure/ack/seq.
- **Browser Level0 (JS)** — локальная очередь (IndexedDB), multi-tab дедуп, доставка событий из браузера/REGART.
- **Packs** — расширения (rules/enrich/fixtures), установка вручную с подписью и проверкой совместимости.

## TLS Core
- Core поддерживает TLS в самом бинарнике через `rustls`.
- Для запуска Core в TLS-режиме задайте:
  - `CORE_TLS_CERT_PATH=/path/to/fullchain.pem`
  - `CORE_TLS_KEY_PATH=/path/to/privkey.pem`
- Если переменные не заданы, Core запускается в plain HTTP (по умолчанию для локального dev).

## Структура репозитория
- `core/` — Art Core (Rust)
- `agent/` — Art Agent (Rust)
- `browser/` — Browser Level0 (JS)
- `apps/console-web` — Tier B Console foundation (workspace app)
- `packages/` — общие пакеты Console (`ui-laws`, `i18n`, `evidence-linking`, `worker-runtime`, `local-stores`)
- `docs/` — документация, контракты, runbooks
- `scripts/` — утилиты и CI-gates

## Навигация
- Главный индекс документации: `docs/README.md`
- Старт: `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- Контракты/схемы и codegen: см. чек-лист 08 в `docs/source/checklists/`
- CI/безопасность поставок (supply-chain): см. чек-лист 04 в `docs/source/checklists/`
- Внешний source-of-truth для REGART этапов 05/06: `https://github.com/neo-2022/my_langgraph_agent`

## Текущее состояние
- Этапы `01..27` закрыты и зафиксированы в `CHECKLIST_00_MASTER_ART_REGART.md`.
- Аудит/ремедиация закрытия этапов зафиксирован в `docs/source/checklists/CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md`.
- Ветка `main` — актуальная рабочая ветка с зелёными обязательными проверками CI/security.

## Contracts
- OpenAPI (введён на Stage 08): `docs/api/openapi.yaml`
- JSON Schema registry (введён на Stage 08): `docs/schemas/`
- API v2 contracts (введены на Stage 28+): `docs/contracts/v2/`
- Актуальность контрактов контролируется CI-проверками (`openapi-validate`, `codegen-diff-clean`, `schemas-md-diff-clean`).

## Безопасность
Правила репорта уязвимостей: `SECURITY.md`.

## Лицензия
Проект является частной собственностью.  
Статус лицензии: **All rights reserved / UNLICENSED**.  
Копирование, распространение и использование без явного письменного разрешения владельца запрещено.
