# План интеграции REGART ↔ Art

Цель: REGART (`my_langgraph_agent`) передаёт в Art все релевантные события и ошибки, а Art остаётся главным источником инцидентов и observability snapshot.

Источники требований:
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- `docs/source/checklists/CHECKLIST_20_PACK_REGART.md`

## 1. Контуры интеграции

### 1.1 Backend (UI Proxy / LangGraph)

- Проксирование и/или bridge endpoint для Art ingest/stream.
- Нормализованные upstream-ошибки с контекстом (where/why/action/evidence).
- Корреляция `run_id/node_id/span_id/trace_id`, когда данные доступны.

### 1.2 Browser (REGART Level0)

- Единый capture ошибок, network, graph/run/debugger signals.
- Очередь доставки в Art c backlog и retry.
- Генерация `observability_gap.*` при недоступности Art/канала.

### 1.3 ОС-уровень (через Art Agent)

- Сбор systemd/journald/ports/net probes для сервисов REGART.
- Фиксация crashloop, startup-failure, port-collision.

## 2. Этапы реализации

1. `Phase A: Contracts`
   - закрепить RawEvent schema для каналов REGART;
   - согласовать правила dedupe/fingerprint/correlation.
2. `Phase B: Transport`
   - подключить ingest + stream, retries и ack semantics;
   - обеспечить корректный CORS/headers в UI Proxy.
3. `Phase C: Browser bridge`
   - отправка событий Level0 в Art;
   - backlog + flush после восстановления.
4. `Phase D: Observability gaps`
   - явные `observability_gap.*` для всех точек потерь.
5. `Phase E: Acceptance`
   - e2e сценарии: cold boot, Art down, REGART down, reconnect/catchup.

## 3. Definition of Done для REGART-интеграции

- Любая ошибка/деградация REGART имеет отражение в Art (RawEvent или Incident).
- Потери событий детектируются как `observability_gap.*`, а не "тишина".
- Панель REGART использует Art как источник статуса/инцидентов, где это предусмотрено.
- E2E чек-листы `05`, `06`, `20` закрыты и связаны с master `00`.
