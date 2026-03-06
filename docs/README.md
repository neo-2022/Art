# Документация Art

Этот каталог — единая точка входа в документацию проекта `Art`.

## 1. Канонические источники

- `docs/source/Art_v1_spec_final.md` — нормативная мастер-спецификация Art v1.
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md` — целевая модель интеграции REGART с Art.
- `docs/source/risk_register_v0_2.md` — обязательный реестр рисков программы 28..38.
- `docs/source/checklists/` — полный набор чек-листов реализации, приёмки и аудита.

Подробный индекс исходников: `docs/source/README.md`.

## 2. Рабочие документы проекта

- `docs/ARCHITECTURE.md` — сжатая архитектурная проекция по компонентам Core/Agent/Browser.
- `docs/INTEGRATION.md` — рабочий план интеграции REGART с Art по этапам.

## 3. Карта чек-листов

- `00` — мастер-план Art+REGART.
- `01..04` — governance, SRE, privacy, региональные профили.
- `05..06` — готовность REGART (UI/Graph/Run/Debugger и bridge в Art).
- `07..16` — репозиторий Art, контракты, Core, pipeline, Panel 0.
- `17..18` — Agent: spool/outbox и receivers.
- `19..20` — framework паков и pack REGART.
- `21..26` — self-observability, тестирование, ops, release, compliance, RU-профиль.
- `27` — аудит соответствия и ремедиация (runtime/CI hardening).
- `28..38` — программа v0.2: monorepo Console foundation, API v2 DNA/Evidence, performance/coverage, SaaS/Linux hardening, ladder enforcement.

Подробный индекс чек-листов: `docs/source/checklists/README.md`.
Детализация этапов `05..06` хранится в репозитории REGART: `https://github.com/neo-2022/my_langgraph_agent`.

## 4. Правило актуальности

1. Канон: `docs/source/*` (копии из внешней папки документации).
2. Рабочая синхронизация: `docs/*.md` (архитектура, интеграция, планы).
3. Любое изменение в каноне должно сопровождаться обновлением:
   - `docs/ARCHITECTURE.md`
   - `docs/INTEGRATION.md`
   - индексов `docs/source/README.md` и `docs/source/checklists/README.md`
