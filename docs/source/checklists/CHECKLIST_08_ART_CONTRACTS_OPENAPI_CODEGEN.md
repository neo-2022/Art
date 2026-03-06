A) Полный запрет опциональности:
# CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry
Файл: CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (contracts/openapi/codegen pass)  
Триггер пересмотра: изменение Art_v1_spec_final.md (контракты); добавление/изменение полей схем; изменение OpenAPI; изменение генераторов codegen
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Сделать контракты v1 однозначными и проверяемыми: schema registry, сверка со спецификацией, unknown-fields tests, negative contract tests, OpenAPI codegen, human-readable docs.

## Границы
Контракты (OpenAPI + JSON Schema) и тесты контрактов.

## Зависимости
CHECKLIST 07 — Art repo WP0 (структура, CI, RU dev docs)

## Статус перепроверки
- Контрактные тесты, OpenAPI gate, codegen и schema-docs генерация перепроверены.
- Пункты этапа закрыты по факту локальных проверок и CI job definition.

## Шаги (строго линейно)

- [x] **1. Сделать:** Создать schema registry `docs/schemas/` с версионированием и индексом.
  - [x] существует каталог `docs/schemas/`
  - [x] существует каталог `docs/schemas/v1/`
  - [x] в `docs/schemas/v1/` присутствуют JSON Schema файлы v1 (минимум):
    - [x] `docs/schemas/v1/raw_event.json`
    - [x] `docs/schemas/v1/ingest_envelope.json`
    - [x] `docs/schemas/v1/ingest_response.json`
    - [x] `docs/schemas/v1/incident.json`
  - [x] существует индекс: `docs/schemas/index.md`
  - [x] индекс содержит для каждого schema:
    - [x] `schema_id` (например `art://schemas/raw_event.json`)
    - [x] `schema_version` (например `1.0`)
    - [x] путь файла в репозитории
    - [x] статус (`active` или `deprecated` — одно из двух)
  - [x] существует `docs/schemas/README.md`, который фиксирует правила registry:
    - [x] правило: новые схемы добавляются только в новый каталог версии (`v2/` и т.д.)
    - [x] правило: изменения в v1 не ломают совместимость (backward compatible)
    - [x] правило: `additionalProperties` допускается (unknown fields не ломают ingest)
  - [x] **Проверка (pass/fail):** `docs/schemas/README.md` и `docs/schemas/index.md` существуют; перечисленные файлы `docs/schemas/v1/*.json` существуют.

- [x] **2. Сделать:** Сверить схемы с обязательными требованиями Art v1 (из Art_v1_spec_final.md) и задокументировать compliance.
  - [x] создан файл `docs/api/schema_compliance.md`
  - [x] в `docs/api/schema_compliance.md` есть таблица соответствия “Spec requirement → Schema field/path → Status”
  - [x] в таблице явно зафиксированы требования из спецификации (минимум):
    - [x] RawEvent: поле называется `severity` (строго)
    - [x] Ingest endpoints v1 (перечень эндпоинтов) отражён в OpenAPI
    - [x] IngestResponse: `invalid_details[]` существует и содержит `index` и `reason`
    - [x] Backpressure: ответы 429/503/413 содержат `retry_after_ms` (если применимо) и описаны в OpenAPI
    - [x] Ack semantics: `ack.upto_seq` контрактно описан (если присутствует)
  - [x] создан файл `docs/api/versioning.md`
  - [x] `docs/api/versioning.md` содержит фиксированные правила:
    - [x] API версия фиксируется в пути `/api/v1/...`
    - [x] схема содержит `schema_version` (если поле предусмотрено схемой) и значение для v1 фиксировано
    - [x] правила bump версии при breaking change (одна фиксированная процедура)
  - [x] **Проверка (pass/fail):** `docs/api/schema_compliance.md` заполнен и содержит перечисленные требования; `docs/api/versioning.md` существует и содержит правила версионирования.

- [x] **3. Сделать:** Добавить unknown-fields contract tests: payloads с лишними полями принимаются, лишние поля игнорируются.
  - [x] существует тестовый набор `test-contracts` (фиксированное имя таргета): `make test-contracts`
  - [x] unknown-fields test для RawEvent:
    - [x] добавлено лишнее поле на верхнем уровне RawEvent (например `extra_top`)
    - [x] добавлено лишнее поле внутри вложенного объекта (например `ctx.extra_nested`)
    - [x] ожидаемое поведение: ingest success (accepted увеличивается, `invalid_details` не содержит запись для этого события)
    - [x] ожидаемое поведение: лишние поля не влияют на обработку (не приводят к invalid и не ломают pipeline)
  - [x] unknown-fields test для IngestEnvelope:
    - [x] лишнее поле в envelope на верхнем уровне (например `envelope_extra`)
    - [x] ожидаемое поведение: ingest success
  - [x] **Проверка (pass/fail):** `make test-contracts` зелёный; тесты явным образом проверяют “accepted без invalid_details” для payload с лишними полями.

- [x] **4. Сделать:** Добавить negative contract tests: invalid_details и backpressure форматы (413/429/503).
  - [x] negative suite входит в `make test-contracts` (единый запуск)
  - [x] invalid_details test:
    - [x] отправляется batch, где 1 элемент валиден, 1 элемент невалиден
    - [x] ожидается partial accept (валидный принят, невалидный учтён)
    - [x] ожидается `invalid_details[]` содержит запись с `index` и `reason`
  - [x] 413 test (payload too large):
    - [x] ожидается HTTP 413
    - [x] тело ответа соответствует контракту error-ответа и содержит `retry_after_ms` (либо `retry_after_ms=null`, но поле описано в контракте) — одно фиксированное решение
  - [x] 429 test (rate limited):
    - [x] ожидается HTTP 429
    - [x] тело ответа содержит `retry_after_ms` (число >= 0)
  - [x] 503 test (service unavailable):
    - [x] ожидается HTTP 503
    - [x] тело ответа содержит `retry_after_ms` (число >= 0)
  - [x] **Проверка (pass/fail):** `make test-contracts` зелёный; negative suite реально проверяет форматы.

- [x] **5. Сделать:** Зафиксировать OpenAPI v1 и codegen для клиентов (Rust/TS) + CI gate “diff clean”.
  - [x] существует OpenAPI файл: `docs/api/openapi.yaml`
  - [x] OpenAPI содержит эндпоинты v1 (минимум):
    - [x] `POST /api/v1/ingest`
    - [x] `GET /api/v1/snapshot`
    - [x] `GET /api/v1/stream`
    - [x] `GET /api/v1/incidents`
    - [x] `POST /api/v1/incidents/{id}/ack`
    - [x] `POST /api/v1/incidents/{id}/resolve`
    - [x] `POST /api/v1/actions/execute`
    - [x] `GET /health`
    - [x] `GET /metrics`
  - [x] OpenAPI описывает ответы backpressure:
    - [x] 413 описан
    - [x] 429 описан
    - [x] 503 описан
    - [x] во всех трёх описано поле `retry_after_ms` в ответе (контрактно)
  - [x] генерация клиентов фиксирована одной командой:
    - [x] `make generate` существует
    - [x] `make generate` генерирует Rust client в `generated/rust/`
    - [x] `make generate` генерирует TS client в `generated/ts/`
  - [x] генерация является CI gate:
    - [x] в CI есть job `codegen-diff-clean`
    - [x] job запускает `make generate`
    - [x] job проверяет `git diff --exit-code` (diff clean)
  - [x] **Проверка (pass/fail):** локально `make generate` даёт чистый diff; в CI job `codegen-diff-clean` зелёный.

- [x] **6. Сделать:** Сгенерировать человекочитаемую документацию по схемам и зафиксировать генератором.
  - [x] существует файл `docs/api/schemas.md`
  - [x] существует генератор (фиксированная команда):
    - [x] `make generate-schemas-md` существует
    - [x] `make generate-schemas-md` перегенерирует `docs/api/schemas.md` из `docs/schemas/index.md` и `docs/schemas/v1/*.json`
  - [x] `docs/api/schemas.md` содержит минимум:
    - [x] перечень схем v1
    - [x] ссылки на файлы схем
    - [x] краткое описание назначений (1–2 строки на схему)
  - [x] **Проверка (pass/fail):** `docs/api/schemas.md` существует; `make generate-schemas-md` обновляет файл детерминированно.

## Документация (RU)
- [x] docs/schemas/README.md
- [x] docs/schemas/index.md
- [x] docs/schemas/v1/raw_event.json
- [x] docs/schemas/v1/ingest_envelope.json
- [x] docs/schemas/v1/ingest_response.json
- [x] docs/schemas/v1/incident.json
- [x] docs/api/openapi.yaml
- [x] docs/api/schema_compliance.md
- [x] docs/api/versioning.md
- [x] docs/api/schemas.md

## Тестирование
- [x] unit: schema validation (JSON Schema validate для всех файлов `docs/schemas/v1/*.json`)
- [x] integration: `make test-contracts` (unknown-fields + negative suite)
- [x] integration: codegen compile:
  - [x] Rust client компилируется
  - [x] TS client компилируется (typecheck/build)

## CI gate
- [x] openapi validate green:
  - [x] в CI есть job `openapi-validate`
  - [x] job валидирует `docs/api/openapi.yaml` (фиксированная команда в repo)
- [x] contract tests green:
  - [x] в CI есть job `test-contracts`
  - [x] job запускает `make test-contracts`
- [x] generate diff clean:
  - [x] в CI есть job `codegen-diff-clean`
  - [x] job запускает `make generate` и проверяет `git diff --exit-code`
- [x] schemas md green:
  - [x] в CI есть job `schemas-md-diff-clean`
  - [x] job запускает `make generate-schemas-md` и проверяет `git diff --exit-code`

## DoD
- [x] Schema registry создан: `docs/schemas/` с `v1/`, `README.md`, `index.md`, и v1-схемами.
- [x] `docs/api/schema_compliance.md` заполнен и отражает требования Art v1.
- [x] Unknown-fields и negative contract tests существуют и зелёные (`make test-contracts`).
- [x] OpenAPI v1 существует и проходит validate.
- [x] Codegen Rust/TS фиксирован, воспроизводим и контролируется CI gate “diff clean”.
- [x] `docs/api/schemas.md` генерируется детерминированно и контролируется CI gate.
