# REGART adversarial integration harness v0.2

## Source of truth
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- `docs/source/checklists/CHECKLIST_20_PACK_REGART.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `formats/regart_adversarial_harness_v0_2.yaml`

## Назначение
Этот документ фиксирует отдельный усиленный тестовый контур, в котором `REGART` используется
как внешний боевой полигон для проверки `Art`.

Важно:
- это дополнение, а не замена внутренних тестов `Art`;
- этот контур увеличивает нагрузку и глубину проверки;
- он не имеет права превращать `Art` в систему, которая “проходит тесты только вместе с REGART”.

## Главный закон
- `Art` обязан проходить базовые runtime/security/release тесты самостоятельно.
- `REGART`-harness используется как второй слой доказательства:
  - проверка настоящей внешней интеграции;
  - проверка длинных цепочек событий;
  - hostile/adversarial сценарии;
  - проверка bridge/backlog/recovery.
- Плавающая зависимость от соседнего checkout или от `main` внешнего репозитория запрещена.

## Модель интеграции

### 1. Кто кому принадлежит
- `Art` — самостоятельная система мониторинга и расследования.
- `REGART` — наблюдаемая внешняя система и источник структурированных сигналов.
- `REGART` не должен быть обязательным условием старта `Art`.
- `Art` не должен внедряться в `REGART` так, чтобы без `Art` `REGART` переставал работать.

### 2. Порядок запуска
1. `Art Core`
2. `Art Agent`
3. `REGART` backend/runtime
4. `REGART UI Proxy`
5. `REGART React UI / Browser Level0`

Причина:
- если `REGART` не поднимется вовсе, `Art` всё равно должен увидеть это через агентный и
  системный контур.

## Три канала данных

### A. OS-уровень
Источник:
- `Art Agent`

Что проверяем:
- `systemd`
- `journald`
- crash/restart loop
- process state
- port probes

Зачем:
- это гарантирует наблюдаемость даже при полном отказе UI и backend.

### B. Backend-уровень
Источники:
- `REGART UI Proxy`
- `LangGraph runtime`
- backend-ошибки и upstream ошибки

Что проверяем:
- structured `RawEvent`
- `upstream_error`
- корректную корреляцию `trace_id / run_id / node_id`
- backlog/retry path

### C. Browser-уровень
Источники:
- `Browser Level0`
- network provider
- UI/runtime ошибки

Что проверяем:
- `window.error`
- `unhandledrejection`
- `ui.graph.empty`
- network failures
- локальный backlog
- bridge `Level0 -> Art`

## Что запрещено
- использовать `REGART` как единственный источник проверки интеграции;
- тянуть внешний truth-path по `HEAD`/`main` без pinning;
- считать sibling checkout “достаточным production baseline”;
- считать HTML/render-проверки достаточным доказательством интеграции;
- закрывать stage 05/06/20/24/38 без hostile suite evidence.

## Pinned source baseline
- Разрешены только 2 формы внешнего источника:
  1. pinned git commit;
  2. локальный snapshot, помеченный commit/tag.
- Запрещены:
  - floating `main`;
  - “последний checkout рядом в каталоге” как единственный truth-source;
  - непомеченный zip/archive без commit provenance.

## Набор обязательных suite

### 1. `art-regart-smoke`
Минимальная цепочка:
- startup order;
- `UI Proxy -> Art`;
- `Level0 -> Art`;
- хотя бы один backend event;
- хотя бы один browser event;
- snapshot/stream подтверждают попадание в `Art`.

### 2. `art-regart-hostile-bridge`
Проверяет:
- недоступность `Art`;
- локальный backlog в `REGART`;
- восстановление связи;
- повторную доставку без silent loss;
- gap-события на время разрыва.

### 3. `art-regart-replay`
Проверяет:
- длинную цепочку событий `run -> tool -> graph -> upstream_error -> recovery`;
- повторное воспроизведение;
- сохранение correlation;
- отсутствие случайного эвристического jump.

### 4. `art-regart-long-chain`
Проверяет:
- длинный run-цикл;
- несколько ошибок и частичных восстановлений;
- accumulation evidence;
- переход в incident и back to healthy.

### 5. `art-regart-actions-audit`
Проверяет:
- path `proposal/preflight/policy/audit`;
- отсутствие локального bypass;
- human-in-the-loop mediation;
- audit trail после действий.

## Что считается полным доказательством
- pinned source указан и проверяем;
- suite-результаты зафиксированы в evidence;
- видно разделение:
  - ошибка `Art`;
  - ошибка `REGART`;
  - ошибка bridge;
- при отказе `Art` события не теряются молча;
- при отказе `REGART` `Art` всё равно видит отказ через OS plane;
- browser-plane не молчит и не исчезает без gap/event.

## Обязательные evidence
- hostile bridge log
- replay log
- long-chain log
- actions/audit mediation log
- pinned source manifest

## Что это решает
- повышает реальность тестовой нагрузки;
- заставляет `Art` выдерживать внешнюю систему, а не только внутренний happy-path;
- одновременно помогает находить ошибки в `REGART`;
- снижает риск ложной зелени в stage 05/06/20/24/38;
- делает интеграцию воспроизводимой и пригодной для due diligence.
