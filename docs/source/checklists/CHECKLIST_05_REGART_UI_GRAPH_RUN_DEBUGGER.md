A) Полный запрет опциональности:
# CHECKLIST 05 — REGART: UI/Graph/Run/Debugger (обёртка)
Файл: CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменения в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`; изменения требований `trace_id`; изменения требований `ui.graph.empty`; изменения требований multi-tab дедуп; изменения поведения UI Proxy / transport

Внешний source-of-truth (REGART):
- Локально (если репозитории рядом): `../my_langgraph_agent/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
- GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`

## Цель
Закрыть REGART UI/Debugger по источнику правды `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` и обеспечить обязательные доработки: `subscribe(listener)`, `trace_id` всегда, `ui.graph.empty`, multi-tab дедуп, `observability_gap.ui_proxy_unavailable`.

## Границы
Чек-лист является обёрткой и не дублирует исходник `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`. Все “реальные” пункты закрываются в исходнике после фактической проверки.

## Зависимости
CHECKLIST 01 — Governance/SRE  
CHECKLIST 02 — Privacy baseline (global)  
CHECKLIST 03 — Regional profiles  
CHECKLIST 04 — Secure SDLC + Supply-chain  

## Шаги (строго линейно)

- [x] **1. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про API `subscribe(listener)` и реализовать его.
  - [x] В исходнике чек-листа добавлен пункт: `Debugger Core API содержит subscribe(listener)`
  - [x] В коде Debugger Core реализован `subscribe(listener)`:
    - [x] listener вызывается для каждого `UiError` (ошибки)
    - [x] listener вызывается для каждого `DebugEvent` (события)
    - [x] listener получает уже нормализованные структуры (после нормализации)
  - [x] Добавлен тест (unit или integration), который подтверждает: listener получает события в правильном порядке и без пропусков
  - [x] **Проверка (pass/fail):** соответствующий пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` с доказательством (команда/лог/вывод тестов).

- [x] **2. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `trace_id` и реализовать правило “trace_id всегда”.
  - [x] В исходнике чек-листа добавлен пункт: `DebugEvent содержит обязательный trace_id (генерируется при отсутствии)`
  - [x] Реализация: если входящий event не содержит `trace_id`, генерируется новый `trace_id` (UUIDv4)
  - [x] Реализация: `trace_id` сохраняется при проксировании событий между слоями (Level0 → UI → UI Proxy → Art)
  - [x] Добавлен тест: при отсутствии `trace_id` в исходном событии, на выходе он присутствует и сохраняется при прохождении по слоям
  - [x] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` с доказательством (2026-03-05: `npm -C ui test -- --run tests/debugger_trace_id.spec.js tests/outbox.spec.js` + `npm -C ui test`).

- [x] **3. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `ui.graph.empty` и реализовать генерацию события при пустом графе.
  - [x] В исходнике чек-листа добавлен пункт: `при пустом графе генерируется kind="ui.graph.empty"`
  - [x] Событие отправляется только когда контейнер >0, fetch завершён, nodes=0 и edges=0; `ctx` содержит `assistant_id`, `container_w/h`, `nodes_count`, `edges_count`, `in_flight`, `last_fetch_ms`, `trace_id`.
  - [x] `ui.graph.empty` содержит `ctx` со строгим набором полей:
    - [x] `assistant_id`
    - [x] `container_w`
    - [x] `container_h`
    - [x] `nodes_count`
    - [x] `edges_count`
    - [x] `in_flight` (true/false)
    - [x] `last_fetch_ms` (число или -1 если неизвестно)
    - [x] `trace_id`
  - [x] Событие генерируется строго при условии: контейнер имеет ненулевой размер, fetch завершён, но `nodes_count=0` и `edges_count=0`
  - [x] Добавлен тест/сценарий воспроизведения, который гарантированно приводит к `ui.graph.empty`
  - [x] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` и событие реально возникает при воспроизведении (`tests/graph_empty.spec.js` + `npm -C ui test`).

- [x] **4. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про multi-tab дедуп и реализовать требуемое поведение “локально видно в обеих вкладках, в Art доставляется ровно один раз”.
  - [x] В исходнике чек-листа добавлен пункт: `multi-tab дедуп обязателен (2 вкладки → 1 доставка в Art)` (`ui/src/multiTabManager.js`).
  - [x] Реализация использует фиксированный механизм “leader tab”:
    - [x] В каждой вкладке создаётся `tab_id` (UUIDv4) и хранится в `sessionStorage` (только для текущей вкладки)
    - [x] Лидер определяется через `localStorage`-lock `regart:art_sender_leader` с heartbeat:
      - [x] лидер пишет `{"tab_id": "...", "ts_ms": ...}` каждые 1000 мс
      - [x] лидерство считается потерянным, если `ts_ms` старше 3000 мс
      - [x] при потере лидерства новая вкладка захватывает lock и становится лидером
    - [x] Только лидер отправляет события в Art (через UI Proxy)
    - [x] Все вкладки (включая лидера) публикуют события в `BroadcastChannel` `regart:debugger_events`
    - [x] Все вкладки отображают события локально из этого канала (поэтому “видно в обеих вкладках”)
  - [x] Dedup на стороне лидера фиксированным ключом `dedup_key`:
    - [x] `dedup_key = sha256(canonical_json(normalized_event))`
    - [x] `canonical_json`: JSON с отсортированными ключами, без полей `ts_ms` и без полей UI-рендеринга (см. `ui/src/multiTabManager.js`)
    - [x] TTL дедуп-таблицы: 300000 мс
  - [x] Добавлен тест/инструкция воспроизведения multi-tab (`tests/multiTabManager.spec.js`) и доказательство, что в Art нет дублей (`tests/outbox.spec.js`, `npm -C ui test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js`).
  - [x] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` и есть evidence (тесты выше).

- [x] **5. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `observability_gap.ui_proxy_unavailable` и реализовать генерацию.
  - [x] В исходнике чек-листа добавлен пункт: `при недоступности UI Proxy генерируется observability_gap.ui_proxy_unavailable` (`ui/src/obs/uiProxyGap.js`).
  - [x] Событие содержит evidence_min: `endpoint`, `status`, `retry_count`, `backoff_ms`, `trace_id` (в payload передаётся текст ошибки или `base_url`).
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` (Stage 01) с `incident_rule` = `create_incident` и `action_ref` → `docs/runbooks/ui_proxy_unavailable.md`.
  - [x] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]`; evidence — `tests/uiProxyGap.spec.js` + ручное отключение UI Proxy приводит к событию в Level0.

## Тестирование
- [x] Автотест подтверждает `subscribe(listener)` и порядок доставки (Шаг 1). Evidence: `ui/tests/debugger_core.spec.js` + `scripts/ci/check_stage05_wrapper.sh` (`npm test -- debugger_core.spec.js`, 2 passed).
- [x] Автотест подтверждает генерацию `trace_id` при отсутствии и сохранение при прохождении по слоям (Шаг 2).
- [x] Автотест/интеграционный сценарий подтверждает генерацию `ui.graph.empty` при выполнении условий (Шаг 3). Evidence: `ui/tests/graph_empty.spec.js` (3 tests passed) + `npm -C ui test -- graph_empty.spec.js`.
  - [x] `tests/graph_empty.spec.js` проверяет helper `buildGraphEmptyEvent` → ctx содержит все поля и `trace_id`.
  - [x] `tests/graph_empty.spec.js` проверяет условия генерации через `buildGraphEmptyEventIfNeeded` (container>0, nodes=0, edges=0, inFlight=false) и null при нарушении условий.
- [x] Автотест/интеграционный сценарий подтверждает multi-tab: 2 вкладки → локально видно в обеих → в Art ровно один раз (Шаг 4) (`tests/multiTabManager.spec.js`, `tests/outbox.spec.js`).
- [x] Автотест/интеграционный сценарий подтверждает `observability_gap.ui_proxy_unavailable` при недоступности UI Proxy (Шаг 5) (`tests/uiProxyGap.spec.js`).

## CI gate
- [x] В CI workflow включён запуск тестов из раздела “Тестирование” (через `scripts/ci/check_stage05_wrapper.sh`, который при необходимости клонирует `https://github.com/neo-2022/my_langgraph_agent.git` и запускает `npm --prefix .tmp/my_langgraph_agent/ui test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js tests/uiProxyGap.spec.js`).
- [x] В CI workflow включён статический gate `scripts/ci/check_stage05_wrapper.sh`, который:
  - [x] проверяет, что в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` присутствуют пункты, добавляемые Шагами 1–5 (по стабильным строкам/паттернам: `multi-tab`, `ui.graph.empty`, `observability_gap.ui_proxy_unavailable`, ссылки на `tests/`), а также на `ui/src/multiTabManager.js` и `ui/src/obs/uiProxyGap.js`.
  - [x] проверяет, что существуют обязательные артефакты для Шага 5: `docs/runbooks/ui_proxy_unavailable.md` (как target `action_ref`) и запись `observability_gap.ui_proxy_unavailable` в `docs/governance/observability_gap_registry.md`.
  - [x] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [x] Все шаги 1–5 этого чек-листа отмечены `[x]` после фактической проверки и упомянуты в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` (разделы multi-tab, ui.graph.empty, observability gap).
- [x] Соответствующие пункты в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` отмечены `[x]` с evidence (тексты + tests + runbook/registry).
- [x] Тесты из раздела “Тестирование” зелёные в CI (гарантирует `scripts/ci/check_stage05_wrapper.sh`).
- [x] CI gate из раздела “CI gate” зелёный в CI (напр. workflow job `stage05-wrapper-gate`).
