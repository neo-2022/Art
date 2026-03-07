A) Полный запрет опциональности:
# CHECKLIST 05 — REGART: UI/Graph/Run/Debugger (обёртка)
Файл: CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменения в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`; изменения требований `trace_id`; изменения требований `ui.graph.empty`; изменения требований multi-tab дедуп; изменения поведения UI Proxy / transport
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

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
- `docs/source/regart_adversarial_integration_harness_v0_2.md`

## Шаги (строго линейно)

- [ ] **1. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про API `subscribe(listener)` и реализовать его.
  - [ ] В исходнике чек-листа добавлен пункт: `Debugger Core API содержит subscribe(listener)`
  - [ ] В коде Debugger Core реализован `subscribe(listener)`:
    - [ ] listener вызывается для каждого `UiError` (ошибки)
    - [ ] listener вызывается для каждого `DebugEvent` (события)
    - [ ] listener получает уже нормализованные структуры (после нормализации)
  - [ ] Добавлен тест (unit или integration), который подтверждает: listener получает события в правильном порядке и без пропусков
  - [ ] **Проверка (pass/fail):** соответствующий пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` с доказательством (команда/лог/вывод тестов).

- [ ] **2. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `trace_id` и реализовать правило “trace_id всегда”.
  - [ ] В исходнике чек-листа добавлен пункт: `DebugEvent содержит обязательный trace_id (генерируется при отсутствии)`
  - [ ] Реализация: если входящий event не содержит `trace_id`, генерируется новый `trace_id` (UUIDv4)
  - [ ] Реализация: `trace_id` сохраняется при проксировании событий между слоями (Level0 → UI → UI Proxy → Art)
  - [ ] Добавлен тест: при отсутствии `trace_id` в исходном событии, на выходе он присутствует и сохраняется при прохождении по слоям
  - [ ] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` с доказательством (2026-03-05: `npm -C ui test -- --run tests/debugger_trace_id.spec.js tests/outbox.spec.js` + `npm -C ui test`).

- [ ] **3. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `ui.graph.empty` и реализовать генерацию события при пустом графе.
  - [ ] В исходнике чек-листа добавлен пункт: `при пустом графе генерируется kind="ui.graph.empty"`
  - [ ] Событие отправляется только когда контейнер >0, fetch завершён, nodes=0 и edges=0; `ctx` содержит `assistant_id`, `container_w/h`, `nodes_count`, `edges_count`, `in_flight`, `last_fetch_ms`, `trace_id`.
  - [ ] `ui.graph.empty` содержит `ctx` со строгим набором полей:
    - [ ] `assistant_id`
    - [ ] `container_w`
    - [ ] `container_h`
    - [ ] `nodes_count`
    - [ ] `edges_count`
    - [ ] `in_flight` (true/false)
    - [ ] `last_fetch_ms` (число или -1 если неизвестно)
    - [ ] `trace_id`
  - [ ] Событие генерируется строго при условии: контейнер имеет ненулевой размер, fetch завершён, но `nodes_count=0` и `edges_count=0`
  - [ ] Добавлен тест/сценарий воспроизведения, который гарантированно приводит к `ui.graph.empty`
  - [ ] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` и событие реально возникает при воспроизведении (`tests/graph_empty.spec.js` + `npm -C ui test`).

- [ ] **4. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про multi-tab дедуп и реализовать требуемое поведение “локально видно в обеих вкладках, в Art доставляется ровно один раз”.
  - [ ] В исходнике чек-листа добавлен пункт: `multi-tab дедуп обязателен (2 вкладки → 1 доставка в Art)` (`ui/src/multiTabManager.js`).
  - [ ] Реализация использует фиксированный механизм “leader tab”:
    - [ ] В каждой вкладке создаётся `tab_id` (UUIDv4) и хранится в `sessionStorage` (только для текущей вкладки)
    - [ ] Лидер определяется через `localStorage`-lock `regart:art_sender_leader` с heartbeat:
      - [ ] лидер пишет `{"tab_id": "...", "ts_ms": ...}` каждые 1000 мс
      - [ ] лидерство считается потерянным, если `ts_ms` старше 3000 мс
      - [ ] при потере лидерства новая вкладка захватывает lock и становится лидером
    - [ ] Только лидер отправляет события в Art (через UI Proxy)
    - [ ] Все вкладки (включая лидера) публикуют события в `BroadcastChannel` `regart:debugger_events`
    - [ ] Все вкладки отображают события локально из этого канала (поэтому “видно в обеих вкладках”)
  - [ ] Dedup на стороне лидера фиксированным ключом `dedup_key`:
    - [ ] `dedup_key = sha256(canonical_json(normalized_event))`
    - [ ] `canonical_json`: JSON с отсортированными ключами, без полей `ts_ms` и без полей UI-рендеринга (см. `ui/src/multiTabManager.js`)
    - [ ] TTL дедуп-таблицы: 300000 мс
  - [ ] Добавлен тест/инструкция воспроизведения multi-tab (`tests/multiTabManager.spec.js`) и доказательство, что в Art нет дублей (`tests/outbox.spec.js`, `npm -C ui test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js`).
  - [ ] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]` и есть evidence (тесты выше).

- [ ] **5. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про `observability_gap.ui_proxy_unavailable` и реализовать генерацию.
  - [ ] В исходнике чек-листа добавлен пункт: `при недоступности UI Proxy генерируется observability_gap.ui_proxy_unavailable` (`ui/src/obs/uiProxyGap.js`).
  - [ ] Событие содержит evidence_min: `endpoint`, `status`, `retry_count`, `backoff_ms`, `trace_id` (в payload передаётся текст ошибки или `base_url`).
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` (Stage 01) с `incident_rule` = `create_incident` и `action_ref` → `docs/runbooks/ui_proxy_unavailable.md`.
  - [ ] **Проверка (pass/fail):** пункт в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` закрыт `[x]`; evidence — `tests/uiProxyGap.spec.js` + ручное отключение UI Proxy приводит к событию в Level0.

- [ ] **6. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про мост `Level0/Network -> Art` и реализовать его как baseline обязанность REGART UI.
  - [ ] В исходнике чек-листа добавлен пункт: `Level0 bridge отправляет errors/events/network в Art с локальным backlog`.
  - [ ] Реализация: важные `Level0` события и network meta передаются в Art ingest через sender с локальным backlog/повторной доставкой.
  - [ ] Реализация: недоступность Art порождает отдельный gap-сигнал и не ломает локальный Debugger overlay.
  - [ ] Реализация: network provider перехватывает UI fetch/XHR path централизованно, а не точечными вызовами.
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` есть пункт про bridge/network provider, закрыт `[x]`; evidence — integration/e2e log с `Art unavailable -> backlog -> recovery`.

- [ ] **7. Сделать:** Внести в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` обязательный пункт про строгую корреляцию `run_id/node_id/trace_id`.
  - [ ] Правило: `run_id` и `node_id` используются только если реально известны по данным; эвристический jump запрещён.
  - [ ] Правило: `trace_id` не теряется при переходе `Level0 -> UI -> UI Proxy -> Art`.
  - [ ] Правило: события Graph/Tool/Model помечаются корреляционными полями без хардкода.
  - [ ] **Проверка (pass/fail):** source-of-truth чек-лист содержит этот пункт и он закрыт `[x]`; evidence — correlation tests/logs.

- [ ] **8. Сделать:** Встроить pinned external adversarial harness для REGART UI/Debugger как обязательное доказательство stage05.
  - [ ] В source-of-truth и wrapper зафиксировано, что floating `main` и sibling checkout без commit provenance запрещены.
  - [ ] Harness имеет pinned source manifest и запускает suite `art-regart-smoke`.
  - [ ] Harness имеет hostile suite `art-regart-hostile-bridge` для UI/Debugger path.
  - [ ] Evidence содержит browser plane, backend plane и OS plane для одного integration run.
  - [ ] **Проверка (pass/fail):** `docs/source/regart_adversarial_integration_harness_v0_2.md` и harness evidence явно покрывают stage05.

## Тестирование
- [ ] Автотест подтверждает `subscribe(listener)` и порядок доставки (Шаг 1). Evidence: `ui/tests/debugger_core.spec.js` + `scripts/ci/check_stage05_wrapper.sh` (`npm test -- debugger_core.spec.js`, 2 passed).
- [ ] Автотест подтверждает генерацию `trace_id` при отсутствии и сохранение при прохождении по слоям (Шаг 2).
- [ ] Автотест/интеграционный сценарий подтверждает генерацию `ui.graph.empty` при выполнении условий (Шаг 3). Evidence: `ui/tests/graph_empty.spec.js` (3 tests passed) + `npm -C ui test -- graph_empty.spec.js`.
  - [ ] `tests/graph_empty.spec.js` проверяет helper `buildGraphEmptyEvent` → ctx содержит все поля и `trace_id`.
  - [ ] `tests/graph_empty.spec.js` проверяет условия генерации через `buildGraphEmptyEventIfNeeded` (container>0, nodes=0, edges=0, inFlight=false) и null при нарушении условий.
- [ ] Автотест/интеграционный сценарий подтверждает multi-tab: 2 вкладки → локально видно в обеих → в Art ровно один раз (Шаг 4) (`tests/multiTabManager.spec.js`, `tests/outbox.spec.js`).
- [ ] Автотест/интеграционный сценарий подтверждает `observability_gap.ui_proxy_unavailable` при недоступности UI Proxy (Шаг 5) (`tests/uiProxyGap.spec.js`).
- [ ] Автотест/интеграционный сценарий подтверждает bridge `Level0/network -> Art` с backlog/recovery и отдельным gap при недоступном Art (Шаг 6).
- [ ] Автотест/интеграционный сценарий подтверждает строгую корреляцию `run_id/node_id/trace_id` без эвристического jump (Шаг 7).
- [ ] pinned external harness suite `art-regart-smoke` и `art-regart-hostile-bridge` зелёные и дают evidence для stage05 (Шаг 8).

## CI gate
- [ ] В CI workflow включён запуск тестов из раздела “Тестирование” через `scripts/ci/check_stage05_wrapper.sh` в двух режимах:
  - [ ] default CI mode (`STAGE05_EXTERNAL_STRICT=0`) не зависит от внешнего репозитория и запускает локальные runtime smoke: `npm --prefix browser test -- test/multitab.e2e.test.js test/outbox.compression.test.js`
  - [ ] strict mode (`STAGE05_EXTERNAL_STRICT=1`) использует локальный checkout `my_langgraph_agent` и запускает source-of-truth тесты `tests/multiTabManager.spec.js tests/outbox.spec.js tests/uiProxyGap.spec.js`
- [ ] В CI workflow включён статический gate `scripts/ci/check_stage05_wrapper.sh`, который:
  - [ ] проверяет, что в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` присутствуют пункты, добавляемые Шагами 1–5 (по стабильным строкам/паттернам: `multi-tab`, `ui.graph.empty`, `observability_gap.ui_proxy_unavailable`, ссылки на `tests/`), а также на `ui/src/multiTabManager.js` и `ui/src/obs/uiProxyGap.js`.
  - [ ] проверяет, что существуют обязательные артефакты для Шага 5: `docs/runbooks/ui_proxy_unavailable.md` (как target `action_ref`) и запись `observability_gap.ui_proxy_unavailable` в `docs/governance/observability_gap_registry.md`.
  - [ ] завершает работу с exit 1 при нарушении любой проверки
- [ ] Harness gate `scripts/ci/check_regart_adversarial_harness.sh` зелёный и запускается вместе с документационным контуром stage05.

## DoD
- [ ] Все шаги 1–5 этого чек-листа отмечены `[x]` после фактической проверки и упомянуты в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` (разделы multi-tab, ui.graph.empty, observability gap).
- [ ] Все шаги 1–8 этого чек-листа отмечены `[x]` после фактической проверки и упомянуты в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` (включая bridge/network/correlation и pinned hostile harness).
- [ ] Соответствующие пункты в `CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` отмечены `[x]` с evidence (тексты + tests + runbook/registry).
- [ ] Тесты из раздела “Тестирование” зелёные в CI (гарантирует `scripts/ci/check_stage05_wrapper.sh`).
- [ ] CI gate из раздела “CI gate” зелёный в CI (напр. workflow job `stage05-wrapper-gate`).

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
