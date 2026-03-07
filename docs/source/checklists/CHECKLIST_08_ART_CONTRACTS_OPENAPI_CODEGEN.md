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

- [ ] **1. Сделать:** Создать schema registry `docs/schemas/` с версионированием и индексом.
  - [ ] существует каталог `docs/schemas/`
  - [ ] существует каталог `docs/schemas/v1/`
  - [ ] в `docs/schemas/v1/` присутствуют JSON Schema файлы v1 (минимум):
    - [ ] `docs/schemas/v1/raw_event.json`
    - [ ] `docs/schemas/v1/ingest_envelope.json`
    - [ ] `docs/schemas/v1/ingest_response.json`
    - [ ] `docs/schemas/v1/incident.json`
  - [ ] существует индекс: `docs/schemas/index.md`
  - [ ] индекс содержит для каждого schema:
    - [ ] `schema_id` (например `art://schemas/raw_event.json`)
    - [ ] `schema_version` (например `1.0`)
    - [ ] путь файла в репозитории
    - [ ] статус (`active` или `deprecated` — одно из двух)
  - [ ] существует `docs/schemas/README.md`, который фиксирует правила registry:
    - [ ] правило: новые схемы добавляются только в новый каталог версии (`v2/` и т.д.)
    - [ ] правило: изменения в v1 не ломают совместимость (backward compatible)
    - [ ] правило: `additionalProperties` допускается (unknown fields не ломают ingest)
  - [ ] **Проверка (pass/fail):** `docs/schemas/README.md` и `docs/schemas/index.md` существуют; перечисленные файлы `docs/schemas/v1/*.json` существуют.

- [ ] **2. Сделать:** Сверить схемы с обязательными требованиями Art v1 (из Art_v1_spec_final.md) и задокументировать compliance.
  - [ ] создан файл `docs/api/schema_compliance.md`
  - [ ] в `docs/api/schema_compliance.md` есть таблица соответствия “Spec requirement → Schema field/path → Status”
  - [ ] в таблице явно зафиксированы требования из спецификации (минимум):
    - [ ] RawEvent: поле называется `severity` (строго)
    - [ ] Ingest endpoints v1 (перечень эндпоинтов) отражён в OpenAPI
    - [ ] IngestResponse: `invalid_details[]` существует и содержит `index` и `reason`
    - [ ] Backpressure: ответы 429/503/413 содержат `retry_after_ms` (если применимо) и описаны в OpenAPI
    - [ ] Ack semantics: `ack.upto_seq` контрактно описан (если присутствует)
  - [ ] создан файл `docs/api/versioning.md`
  - [ ] `docs/api/versioning.md` содержит фиксированные правила:
    - [ ] API версия фиксируется в пути `/api/v1/...`
    - [ ] схема содержит `schema_version` (если поле предусмотрено схемой) и значение для v1 фиксировано
    - [ ] правила bump версии при breaking change (одна фиксированная процедура)
  - [ ] **Проверка (pass/fail):** `docs/api/schema_compliance.md` заполнен и содержит перечисленные требования; `docs/api/versioning.md` существует и содержит правила версионирования.

- [ ] **3. Сделать:** Добавить unknown-fields contract tests: payloads с лишними полями принимаются, лишние поля игнорируются.
  - [ ] существует тестовый набор `test-contracts` (фиксированное имя таргета): `make test-contracts`
  - [ ] unknown-fields test для RawEvent:
    - [ ] добавлено лишнее поле на верхнем уровне RawEvent (например `extra_top`)
    - [ ] добавлено лишнее поле внутри вложенного объекта (например `ctx.extra_nested`)
    - [ ] ожидаемое поведение: ingest success (accepted увеличивается, `invalid_details` не содержит запись для этого события)
    - [ ] ожидаемое поведение: лишние поля не влияют на обработку (не приводят к invalid и не ломают pipeline)
  - [ ] unknown-fields test для IngestEnvelope:
    - [ ] лишнее поле в envelope на верхнем уровне (например `envelope_extra`)
    - [ ] ожидаемое поведение: ingest success
  - [ ] **Проверка (pass/fail):** `make test-contracts` зелёный; тесты явным образом проверяют “accepted без invalid_details” для payload с лишними полями.

- [ ] **4. Сделать:** Добавить negative contract tests: invalid_details и backpressure форматы (413/429/503).
  - [ ] negative suite входит в `make test-contracts` (единый запуск)
  - [ ] invalid_details test:
    - [ ] отправляется batch, где 1 элемент валиден, 1 элемент невалиден
    - [ ] ожидается partial accept (валидный принят, невалидный учтён)
    - [ ] ожидается `invalid_details[]` содержит запись с `index` и `reason`
  - [ ] 413 test (payload too large):
    - [ ] ожидается HTTP 413
    - [ ] тело ответа соответствует контракту error-ответа и содержит `retry_after_ms` (либо `retry_after_ms=null`, но поле описано в контракте) — одно фиксированное решение
  - [ ] 429 test (rate limited):
    - [ ] ожидается HTTP 429
    - [ ] тело ответа содержит `retry_after_ms` (число >= 0)
  - [ ] 503 test (service unavailable):
    - [ ] ожидается HTTP 503
    - [ ] тело ответа содержит `retry_after_ms` (число >= 0)
  - [ ] **Проверка (pass/fail):** `make test-contracts` зелёный; negative suite реально проверяет форматы.

- [ ] **5. Сделать:** Зафиксировать OpenAPI v1 и codegen для клиентов (Rust/TS) + CI gate “diff clean”.
  - [ ] существует OpenAPI файл: `docs/api/openapi.yaml`
  - [ ] OpenAPI содержит эндпоинты v1 (минимум):
    - [ ] `POST /api/v1/ingest`
    - [ ] `GET /api/v1/snapshot`
    - [ ] `GET /api/v1/stream`
    - [ ] `GET /api/v1/incidents`
    - [ ] `POST /api/v1/incidents/{id}/ack`
    - [ ] `POST /api/v1/incidents/{id}/resolve`
    - [ ] `POST /api/v1/actions/execute`
    - [ ] `GET /health`
    - [ ] `GET /metrics`
  - [ ] OpenAPI описывает ответы backpressure:
    - [ ] 413 описан
    - [ ] 429 описан
    - [ ] 503 описан
    - [ ] во всех трёх описано поле `retry_after_ms` в ответе (контрактно)
  - [ ] генерация клиентов фиксирована одной командой:
    - [ ] `make generate` существует
    - [ ] `make generate` генерирует Rust client в `generated/rust/`
    - [ ] `make generate` генерирует TS client в `generated/ts/`
  - [ ] генерация является CI gate:
    - [ ] в CI есть job `codegen-diff-clean`
    - [ ] job запускает `make generate`
    - [ ] job проверяет `git diff --exit-code` (diff clean)
  - [ ] **Проверка (pass/fail):** локально `make generate` даёт чистый diff; в CI job `codegen-diff-clean` зелёный.

- [ ] **6. Сделать:** Сгенерировать человекочитаемую документацию по схемам и зафиксировать генератором.
  - [ ] существует файл `docs/api/schemas.md`
  - [ ] существует генератор (фиксированная команда):
    - [ ] `make generate-schemas-md` существует
    - [ ] `make generate-schemas-md` перегенерирует `docs/api/schemas.md` из `docs/schemas/index.md` и `docs/schemas/v1/*.json`
  - [ ] `docs/api/schemas.md` содержит минимум:
    - [ ] перечень схем v1
    - [ ] ссылки на файлы схем
    - [ ] краткое описание назначений (1–2 строки на схему)
  - [ ] **Проверка (pass/fail):** `docs/api/schemas.md` существует; `make generate-schemas-md` обновляет файл детерминированно.

## Документация (RU)
- [ ] docs/schemas/README.md
- [ ] docs/schemas/index.md
- [ ] docs/schemas/v1/raw_event.json
- [ ] docs/schemas/v1/ingest_envelope.json
- [ ] docs/schemas/v1/ingest_response.json
- [ ] docs/schemas/v1/incident.json
- [ ] docs/api/openapi.yaml
- [ ] docs/api/schema_compliance.md
- [ ] docs/api/versioning.md
- [ ] docs/api/schemas.md

## Тестирование
- [ ] unit: schema validation (JSON Schema validate для всех файлов `docs/schemas/v1/*.json`)
- [ ] integration: `make test-contracts` (unknown-fields + negative suite)
- [ ] integration: codegen compile:
  - [ ] Rust client компилируется
  - [ ] TS client компилируется (typecheck/build)

## CI gate
- [ ] openapi validate green:
  - [ ] в CI есть job `openapi-validate`
  - [ ] job валидирует `docs/api/openapi.yaml` (фиксированная команда в repo)
- [ ] contract tests green:
  - [ ] в CI есть job `test-contracts`
  - [ ] job запускает `make test-contracts`
- [ ] generate diff clean:
  - [ ] в CI есть job `codegen-diff-clean`
  - [ ] job запускает `make generate` и проверяет `git diff --exit-code`
- [ ] schemas md green:
  - [ ] в CI есть job `schemas-md-diff-clean`
  - [ ] job запускает `make generate-schemas-md` и проверяет `git diff --exit-code`

## DoD
- [ ] Schema registry создан: `docs/schemas/` с `v1/`, `README.md`, `index.md`, и v1-схемами.
- [ ] `docs/api/schema_compliance.md` заполнен и отражает требования Art v1.
- [ ] Unknown-fields и negative contract tests существуют и зелёные (`make test-contracts`).
- [ ] OpenAPI v1 существует и проходит validate.
- [ ] Codegen Rust/TS фиксирован, воспроизводим и контролируется CI gate “diff clean”.
- [ ] `docs/api/schemas.md` генерируется детерминированно и контролируется CI gate.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
