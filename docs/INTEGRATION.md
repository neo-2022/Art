# Интеграция Art ↔ REGART

## Source of truth
- [REGART -  LangGraph  взаимодействие с Art описание.md](source/REGART%20-%20%20LangGraph%20%20взаимодействие%20с%20Art%20описание.md)
- [Art_v1_spec_final.md](source/Art_v1_spec_final.md)
- [CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md](source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md)
- [CHECKLIST_06_REGART_ART_BRIDGE.md](source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md)
- [CHECKLIST_20_PACK_REGART.md](source/checklists/CHECKLIST_20_PACK_REGART.md)

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

## Операционные ссылки
- runbook моста: [art_bridge_runbook.md](regart/art_bridge_runbook.md)
- формат upstream-ошибок: [upstream_error_format.md](regart/upstream_error_format.md)
- parity и platform evidence отслеживаются через stage37 и delivery evidence
