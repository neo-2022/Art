A) Полный запрет опциональности:
# CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
Файл: CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (pass)  
Триггер пересмотра: изменение ingest контракта; изменение backpressure; изменение `invalid_details`; изменение ack/seq семантики
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Сделать ingest полностью детерминированным: `invalid_details` обязателен для частично/полностью невалидных батчей; backpressure обязателен (503/429/413 + `retry_after_ms`); ack/seq семантика однозначна (`ack.upto_seq`); метрики ingest обязательны (`ingest_dropped_total`, `ingest_accepted_total`, `ingest_invalid_total`); chaos обязателен.

## Границы
Только ingest v1 (HTTP API + поведение при перегрузке/ошибках + ack/seq контракт). Storage и VACUUM — в Stage 11.

## Зависимости
- CHECKLIST 11 — Art Core Storage v1 (SQLite)
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Статус перепроверки
- Этап подтверждён проверками runtime+docs+CI gate.

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать ingest протокол v1 (батч/частичный accept/seq/ack) в документации.
  - [x] `POST /api/v1/ingest` принимает batch событий (список)
  - [x] Core назначает каждому принятому событию монотонный `seq` (целое, растёт)
  - [x] В ответе ingest возвращается `ack.upto_seq` (максимальный seq, который гарантированно сохранён)
  - [x] `ack.upto_seq` всегда присутствует в ответе (целое >= 0)
  - [x] **Проверка (pass/fail):** существует `docs/core/ingest_protocol.md`, содержит все пункты выше явно и включает 1 пример запроса/ответа.

- [x] **2. Сделать:** Реализовать `invalid_details` в ответе ingest для невалидных событий (без двусмысленности).
  - [x] `invalid_details` присутствует всегда (даже если пустой массив)
  - [x] каждая запись `invalid_details[]` содержит:
    - [x] `index` (индекс элемента батча, целое >= 0)
    - [x] `reason` (строка)
    - [x] `path` (строка JSONPath или dotted path)
    - [x] `code` (строка, enum из фиксированного списка)
  - [x] фиксированный список `code` (enum) описан в `docs/api/errors.md`
  - [x] поведение partial accept:
    - [x] валидные элементы сохраняются и учитываются в `ack.upto_seq`
    - [x] невалидные элементы не сохраняются и перечислены в `invalid_details`
  - [x] **Проверка (pass/fail):** integration тест отправляет batch (валидный + невалидный) и проверяет:
    - [x] `invalid_details` присутствует
    - [x] `invalid_details` содержит `index/reason/path/code`
    - [x] `ack.upto_seq` соответствует сохранённому валидному событию.

- [x] **3. Сделать:** Реализовать overload backpressure: 503 + `retry_after_ms` при перегрузке очереди/ресурсов.
  - [x] критерий перегрузки определён (фиксированно): превышение `ingest_queue_depth_limit` (число) или `ingest_inflight_limit` (число)
  - [x] при перегрузке возвращается HTTP 503
  - [x] ответ содержит `retry_after_ms` (число >= 0)
  - [x] генерируется `observability_gap.ingest_overloaded` (snapshot/stream)
  - [x] `observability_gap.ingest_overloaded` зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/ingest_overloaded.md`
  - [x] **Проверка (pass/fail):** load smoke тест воспроизводит 503 и `retry_after_ms`, и подтверждает появление `observability_gap.ingest_overloaded` в snapshot/stream.

- [x] **4. Сделать:** Реализовать backpressure для payload limits: 413 + `retry_after_ms` и контрактный error body.
  - [x] при превышении размера запроса возвращается HTTP 413
  - [x] ответ содержит `retry_after_ms` (число >= 0)
  - [x] ответ соответствует контракту error-ответа (описан в OpenAPI + docs/api/errors.md)
  - [x] генерируется `observability_gap.ingest_payload_too_large` (snapshot/stream)
  - [x] событие зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/ingest_payload_too_large.md`
  - [x] **Проверка (pass/fail):** integration тест отправляет payload > max и проверяет 413 + `retry_after_ms` + наличие gap события.

- [x] **5. Сделать:** Реализовать метрики ingest (обязательные).
  - [x] `ingest_accepted_total` увеличивается на количество сохранённых событий
  - [x] `ingest_invalid_total` увеличивается на количество невалидных событий
  - [x] `ingest_dropped_total` увеличивается, если событие было принято в обработку, но не может быть сохранено (storage error)
  - [x] метрики доступны в `GET /metrics`
  - [x] **Проверка (pass/fail):** `/metrics` содержит все 3 метрики; integration тест форсит storage error и проверяет рост `ingest_dropped_total`.

- [x] **6. Сделать:** Реализовать gap события на отказ ingest: `observability_gap.ingest_unavailable`.
  - [x] при недоступности storage/невозможности принимать ingest возвращается HTTP 503 + `retry_after_ms`
  - [x] генерируется `observability_gap.ingest_unavailable` (snapshot/stream)
  - [x] событие содержит evidence_min: причина, error string, queue depth/inflight (если есть), `retry_after_ms`, `trace_id`
  - [x] событие зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/ingest_unavailable.md`
  - [x] **Проверка (pass/fail):** induced test переводит storage в ошибку и проверяет 503+`retry_after_ms` + событие в snapshot/stream.

- [x] **7. Сделать:** Провести chaos тесты ingest (обязательные): kill -9 во время ingest; disk full; восстановление.
  - [x] chaos: kill -9 Core во время ingest
    - [x] после рестарта Core: ingest снова принимает события
    - [x] `ack.upto_seq` остаётся монотонным
  - [x] chaos: disk full
    - [x] ingest отвечает 503 + `retry_after_ms`
    - [x] генерируется `observability_gap.ingest_unavailable`
  - [x] recovery:
    - [x] после освобождения места ingest возвращается в нормальный режим без ручной правки данных
  - [x] **Проверка (pass/fail):** существует документ `docs/ops/ingest_chaos.md` с точными шагами воспроизведения и критериями pass/fail; smoke chaos прогоняется в CI.

## Документация (RU)
- [x] docs/core/ingest_protocol.md
- [x] docs/api/errors.md
- [x] docs/metrics/ingest.md
- [x] docs/ops/ingest_chaos.md
- [x] docs/runbooks/ingest_overloaded.md
- [x] docs/runbooks/ingest_payload_too_large.md
- [x] docs/runbooks/ingest_unavailable.md

## Тестирование
- [x] integration: invalid_details + partial accept + ack.upto_seq (шаг 2)
- [x] load smoke: overload 503 + retry_after_ms + gap event (шаг 3)
- [x] integration: 413 + retry_after_ms + gap event (шаг 4)
- [x] integration: storage error → ingest_dropped_total (шаг 5)
- [x] chaos: kill -9 + disk full + recovery (шаг 7)

## CI gate
- [x] CI job `ingest-integration` существует и зелёный (шага 2/4/5/6)
- [x] CI job `ingest-load-smoke` существует и зелёный (шага 3)
- [x] CI job `ingest-chaos-smoke` существует и зелёный (шага 7)
- [x] CI job `stage12-docs-gate` существует и запускает `scripts/ci/check_ingest_stage12_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/core/ingest_protocol.md` содержит `ack.upto_seq` и `seq`
    - [x] `docs/api/errors.md` содержит `invalid_details` и `retry_after_ms`
    - [x] `docs/metrics/ingest.md` содержит `ingest_dropped_total`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Ingest соответствует контрактам v1: `invalid_details` всегда, `ack.upto_seq` всегда, backpressure реализован (503/413 + retry_after_ms).
- [x] Метрики ingest присутствуют и проверены тестами.
- [x] `observability_gap.ingest_overloaded` и `observability_gap.ingest_unavailable` определены, зарегистрированы и имеют runbook.
- [x] Chaos сценарии воспроизводимы и smoke прогоняются в CI.
- [x] CI gate Stage 12 зелёный.
