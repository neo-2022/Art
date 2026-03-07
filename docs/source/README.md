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
7. `ingress_perimeter_protection_v0_2.md`
   - Тип: спецификация защитного ingress/perimeter контура.
   - Назначение: обязательный anti-DDoS / hostile-ingress baseline для internet-exposed и межсегментных deployment-профилей.
8. `trust_boundary_hardening_v0_2.md`
   - Тип: спецификация границы доверия.
   - Назначение: запрет на использование недоверенного actor-context как security/audit истины.
9. `browser_surface_hardening_v0_2.md`
   - Тип: спецификация browser surface hardening.
   - Назначение: обязательный CSP/header/frame/integrity baseline для Browser Level0, Panel0, Console и showcase-слоя.
10. `regart_adversarial_integration_harness_v0_2.md`
   - Тип: спецификация pinned external adversarial harness.
   - Назначение: обязательный внешний hostile-полигон для `Art <-> REGART` и partner-exposed integration proof.
11. `connected_system_visibility_v0_2.md`
   - Тип: спецификация Connected System View.
   - Назначение: обязательный контур видимости подключённых внешних систем, их статуса, типов данных и declared-vs-observed покрытия.
12. `protective_safeguards_catalog_v0_2.md`
   - Тип: каталог обязательных предохранителей.
   - Назначение: единый список защитных механизмов проекта, чтобы предохранители не терялись между корнем, аудитом, remediation и stage-листами.
13. `storage_pressure_protection_v0_2.md`
   - Тип: защитная спецификация storage.
   - Назначение: правила controlled degraded mode, watermarks и реакции на медленное переполнение SQLite/WAL/disk.
14. `startup_config_safety_validator_v0_2.md`
   - Тип: защитная спецификация fail-closed запуска.
   - Назначение: обязательный валидатор unsafe-конфигурации до перехода системы в `ready` state.
15. `queue_integrity_protection_v0_2.md`
   - Тип: защитная спецификация очередей.
   - Назначение: правила budget, anti-loop, duplicate protection и controlled degradation для backlog/spool/replay путей.
16. `guard_self_observability_v0_2.md`
   - Тип: защитная спецификация самонаблюдаемости guard-механизмов.
   - Назначение: запрет на “молчаливую смерть” защитных контуров без self-test, heartbeat и blocker-механики.
17. `../foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
   - Тип: исторический и концептуальный корневой документ.
   - Назначение: содержит не только историю и differentiators, но и канонический `Threat Model Appendix` с честной зрелостью угроз, защит и missing-контуров.

## Корень дерева решений и автосинхронизация

Корневые документы проекта, в порядке приоритета:
1. `FOUNDATION_CONSTITUTION_V0_2.md`
2. `../foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
3. `Art_v1_spec_final.md`
4. `REGART -  LangGraph  взаимодействие с Art описание.md`

Правило:
- изменение любого корневого документа требует синхронного обновления зависимых документов;
- список зависимостей задаётся в `../../formats/root_decision_tree_dependencies.yaml`;
- CI-gate `scripts/ci/check_root_decision_tree_sync.sh` блокирует merge при рассинхроне.
- Ствол дерева решений: полный аудит -> дефектовочная контрольная ведомость -> дефектовочная лестница remediation -> `MASTER`.
- `MASTER` завершает ствол и управляет кроной, но corrective-порядок получает от предыдущего слоя ствола.
- Дефектовочная контрольная ведомость задаёт поштучный контроль устранения недостатков, а дефектовочная лестница задаёт порядок corrective-движения снизу вверх.
- Для обзорной навигации и контроля документного дрейфа используется
  `../portal/DOCUMENTATION_TREE.md` вместе с machine-readable снимком
  `../../formats/documentation_tree_v0_2.yaml`.
- Этот контур показывает:
  - все документные связи от корня `README.md`;
  - количество документов и суммарное число строк в дереве;
  - число строк у конкретного документа;
  - каталоговые узлы с суммой строк по содержимому;
  - документы, которые влияют на корневой `README.md`.

## Чек-листы

- Каталог: `checklists/`
- Индекс: `checklists/README.md`
- Внешние source-of-truth для REGART-части (этапы 05/06):
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`

## Политика изменений

- Файлы в `docs/source/` считаются каноном и не редактируются "по месту", кроме случаев явной синхронизации с внешним источником.
- Корневые документы дерева решений не имеют права меняться без синхронного обновления зависимого контура.
- Канон обязан оставаться человекочитаемым: даже нормативный документ должен объяснять смысл решения, а не только фиксировать правило.
- Сложные термины, сокращения и англоязычные слова в каноне должны иметь пояснение, перевод или явную ссылку на раскрывающий документ.
- Threat Model для проекта не выносится в отдельный “висящий” канонический файл: его исторический и презентационный source-of-truth живёт внутри `../foundation/PROJECT_HISTORY_AND_CONCEPTS.md`.
- Если меняется документ, который попадает в граф документации, его строковые счётчики и связи в
  `DOCUMENTATION_TREE.md` обязаны быть пересчитаны автоматически и пройти соответствующий CI-gate.
- Нормализация структуры и навигации делается в:
  - `docs/README.md`
  - `docs/ARCHITECTURE.md`
  - `docs/INTEGRATION.md`
  - `docs/source/checklists/README.md`
