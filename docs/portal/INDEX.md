# Портал Документации Art

## Source of truth (обязательно)
- `docs/README.md`
- `docs/source/README.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/INTEGRATION.md`
- REGART external source-of-truth:
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`

## Назначение
Портал является навигационным слоем над существующей документацией и не заменяет канон.

## Быстрые пути
- Product/Architecture: `docs/ARCHITECTURE.md`
- Integration Art↔REGART: `docs/INTEGRATION.md`
- Checklist program: `docs/source/checklists/*`
- RAG: `docs/rag/*`

## REGART ↔ Art Integration
- Быстрый старт: `docs/INTEGRATION.md`
- Контуры интеграции:
  - Backend/UI Proxy
  - Browser Level0
  - OS Agent
- Контракты событий/ошибок: `docs/api/*`, `docs/source/checklists/CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md`
- Actions/control plane: `docs/source/secure_actions_protocol_v2.md`
- Интеграционные тесты/acceptance: `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`, `CHECKLIST_06_*`
- Troubleshooting: `docs/regart/art_bridge_runbook.md`

## UI language routing
- RU default path: `/docs/`
- EN path: `/docs/en/`
- UI выбирает путь по `ui_locale`.
