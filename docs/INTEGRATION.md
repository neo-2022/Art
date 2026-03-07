# Интеграция Art ↔ REGART

## Source of truth
- [REGART -  LangGraph  взаимодействие с Art описание.md](source/REGART -  LangGraph  взаимодействие с Art описание.md)
- [Art_v1_spec_final.md](source/Art_v1_spec_final.md)
- [CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md](source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md)
- [CHECKLIST_06_REGART_ART_BRIDGE.md](source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md)
- [CHECKLIST_20_PACK_REGART.md](source/checklists/CHECKLIST_20_PACK_REGART.md)
- [regart_adversarial_integration_harness_v0_2.md](source/regart_adversarial_integration_harness_v0_2.md)
- [defect_remediation_ladder_v0_2.md](testing/defect_remediation_ladder_v0_2.md)
- `formats/root_decision_tree_dependencies.yaml`

## Кратко

Art и REGART — это интегрированные системы, а не смешанная кодовая база.

Цель интеграции:
- REGART передаёт в Art значимые операционные сигналы
- Art остаётся источником истины для incidents, evidence и degraded-state visibility
- потеря сигнала всегда превращается в явный `observability_gap.*`, а не в молчаливую потерю

## Плоскости интеграции

### Backend plane
- события UI Proxy и серверной части
- нормализованная модель upstream-ошибок
- корреляция через `trace_id`, `run_id`, `node_id` и смежные идентификаторы

### Browser plane
- capture клиентских и UX-сигналов через Level0
- backlog, retry, flush и reconnect semantics
- явные gap-события при недоступности Art

### OS plane
- сбор systemd, journald, ports, probes и process state через Art Agent
- вывод startup failure, crash loop и service health обратно в Art

## Принципы поставки
- ни один transport path не считается надёжным без явного delivery behavior
- все failure states обязаны быть видимыми как events или gaps
- acceptance criteria подтверждаются evidence
- cross-repo parity должна быть машинно проверяемой
- изменение корневого REGART integration source-of-truth требует синхронного обновления этого документа и зависимого контура по `formats/root_decision_tree_dependencies.yaml`
- console/browser integration не считается доказанной только по HTML/render-проверкам; для hostile production стандарта нужен отдельный e2e/runtime proof contour из defect-линии `DEF-018`

## Операционные ссылки
- runbook моста: [art_bridge_runbook.md](regart/art_bridge_runbook.md)
- формат upstream-ошибок: [upstream_error_format.md](regart/upstream_error_format.md)
- parity и platform evidence отслеживаются через stage37 и delivery evidence

## Pinned external adversarial harness
- Для `Art <-> REGART` readiness запрещено использовать floating `main` или “просто соседний checkout” как единственное доказательство интеграции.
- Обязательный внешний hostile harness задан в [regart_adversarial_integration_harness_v0_2.md](source/regart_adversarial_integration_harness_v0_2.md).
- Обязательные suite:
  - `art-regart-smoke`
  - `art-regart-hostile-bridge`
  - `art-regart-replay`
  - `art-regart-long-chain`
  - `art-regart-actions-audit`
- Этот harness усиливает тестовую нагрузку и не заменяет standalone proof самого `Art`.

## Связь со стволом corrective remediation
- Интеграционный контур не живёт отдельно от ствола проекта.
- Порядок corrective-работ определяется:
  - [defect_remediation_control_matrix_v0_2.md](testing/defect_remediation_control_matrix_v0_2.md)
  - [defect_remediation_ladder_v0_2.md](testing/defect_remediation_ladder_v0_2.md)
- Сейчас нижний runtime-basement `DEF-001 -> stage11` уже закрыт честно.
- Активный downstream corrective слой для этого же дефекта переместился в `stage23/37`, где добивается production-ready DR / deploy / platform continuation; в `stage23` уже materialized fail-closed contour для `tls_config_invalid` с persisted startup backlog, а незакрытым blocker'ом остаётся только TLS hot-reload без простоя.
- Интеграционные hostile suites `Art <-> REGART` не подменяют этот basement и не доказывают его вместо него; они подключаются как усиление на своих stage-узлах после того, как нижний storage-basement уже материализован.
