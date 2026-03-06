# Индекс исходных документов

В этом каталоге лежат канонические (внешние) документы, импортированные в репозиторий Art.

## Основные документы

1. `Art_v1_spec_final.md`
   - Тип: нормативная спецификация (RFC-стиль).
   - Назначение: обязательные требования v1 по архитектуре, протоколам, хранению, инцидентам, безопасности и эксплуатации.
2. `REGART -  LangGraph  взаимодействие с Art описание.md`
   - Тип: интеграционный дизайн-документ.
   - Назначение: как REGART (my_langgraph_agent) должен работать с Art в модели "100% observability".
3. `FOUNDATION_CONSTITUTION_V0_2.md`
   - Тип: конституционный документ исполнения v0.2.
   - Назначение: обязательные инварианты monorepo, Tier A/B/C, API v2, process law и CI-gates программы 28..38.
4. `dna_core_determinism_performance_assurance.md`
   - Тип: обязательный стандарт устойчивости DNA Core.
   - Назначение: formal model + property-based + heavy gate 1M + reference parity + canary/rollback law.
5. `risk_register_v0_2.md`
   - Тип: реестр принятых рисков программы 28..38.
   - Назначение: обязательные контрмеры, CI-gates, release-blocker условия.
6. `analytics_memory_v0_2.md`
   - Тип: спецификация operational analytics памяти.
   - Назначение: chart-ready данные + авто-инструкции по статистике инцидентов.

## Чек-листы

- Каталог: `checklists/`
- Индекс: `checklists/README.md`
- Внешние source-of-truth для REGART-части (этапы 05/06):
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`

## Политика изменений

- Файлы в `docs/source/` считаются каноном и не редактируются "по месту", кроме случаев явной синхронизации с внешним источником.
- Нормализация структуры и навигации делается в:
  - `docs/README.md`
  - `docs/ARCHITECTURE.md`
  - `docs/INTEGRATION.md`
  - `docs/source/checklists/README.md`
