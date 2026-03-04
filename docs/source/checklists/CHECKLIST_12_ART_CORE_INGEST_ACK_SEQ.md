A) Полный запрет опциональности:
# CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
Файл: CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение ingest контракта; изменение backpressure; изменение `invalid_details`; изменение ack/seq семантики

## Цель
Сделать ingest полностью детерминированным: `invalid_details` обязателен для частично/полностью невалидных батчей; backpressure обязателен (503/429/413 + `retry_after_ms`); ack/seq семантика однозначна (`ack.upto_seq`); метрики ingest обязательны (`ingest_dropped_total`, `ingest_accepted_total`, `ingest_invalid_total`); chaos обязателен.

## Границы
Только ingest v1 (HTTP API + поведение при перегрузке/ошибках + ack/seq контракт). Storage и VACUUM — в Stage 11.

## Зависимости
- CHECKLIST 11 — Art Core Storage v1 (SQLite)
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать ingest протокол v1 (батч/частичный accept/seq/ack) в документации.
  - [ ] `POST /api/v1/ingest` принимает batch событий (список)
  - [ ] Core назначает каждому принятому событию монотонный `seq` (целое, растёт)
  - [ ] В ответе ingest возвращается `ack.upto_seq` (максимальный seq, который гарантированно сохранён)
  - [ ] `ack.upto_seq` всегда присутствует в ответе (целое >= 0)
  - [ ] **Проверка (pass/fail):** существует `docs/core/ingest_protocol.md`, содержит все пункты выше явно и включает 1 пример запроса/ответа.

- [ ] **2. Сделать:** Реализовать `invalid_details` в ответе ingest для невалидных событий (без двусмысленности).
  - [ ] `invalid_details` присутствует всегда (даже если пустой массив)
  - [ ] каждая запись `invalid_details[]` содержит:
    - [ ] `index` (индекс элемента батча, целое >= 0)
    - [ ] `reason` (строка)
    - [ ] `path` (строка JSONPath или dotted path)
    - [ ] `code` (строка, enum из фиксированного списка)
  - [ ] фиксированный список `code` (enum) описан в `docs/api/errors.md`
  - [ ] поведение partial accept:
    - [ ] валидные элементы сохраняются и учитываются в `ack.upto_seq`
    - [ ] невалидные элементы не сохраняются и перечислены в `invalid_details`
  - [ ] **Проверка (pass/fail):** integration тест отправляет batch (валидный + невалидный) и проверяет:
    - [ ] `invalid_details` присутствует
    - [ ] `invalid_details` содержит `index/reason/path/code`
    - [ ] `ack.upto_seq` соответствует сохранённому валидному событию.

- [ ] **3. Сделать:** Реализовать overload backpressure: 503 + `retry_after_ms` при перегрузке очереди/ресурсов.
  - [ ] критерий перегрузки определён (фиксированно): превышение `ingest_queue_depth_limit` (число) или `ingest_inflight_limit` (число)
  - [ ] при перегрузке возвращается HTTP 503
  - [ ] ответ содержит `retry_after_ms` (число >= 0)
  - [ ] генерируется `observability_gap.ingest_overloaded` (snapshot/stream)
  - [ ] `observability_gap.ingest_overloaded` зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/ingest_overloaded.md`
  - [ ] **Проверка (pass/fail):** load smoke тест воспроизводит 503 и `retry_after_ms`, и подтверждает появление `observability_gap.ingest_overloaded` в snapshot/stream.

- [ ] **4. Сделать:** Реализовать backpressure для payload limits: 413 + `retry_after_ms` и контрактный error body.
  - [ ] при превышении размера запроса возвращается HTTP 413
  - [ ] ответ содержит `retry_after_ms` (число >= 0)
  - [ ] ответ соответствует контракту error-ответа (описан в OpenAPI + docs/api/errors.md)
  - [ ] генерируется `observability_gap.ingest_payload_too_large` (snapshot/stream)
  - [ ] событие зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/ingest_payload_too_large.md`
  - [ ] **Проверка (pass/fail):** integration тест отправляет payload > max и проверяет 413 + `retry_after_ms` + наличие gap события.

- [ ] **5. Сделать:** Реализовать метрики ingest (обязательные).
  - [ ] `ingest_accepted_total` увеличивается на количество сохранённых событий
  - [ ] `ingest_invalid_total` увеличивается на количество невалидных событий
  - [ ] `ingest_dropped_total` увеличивается, если событие было принято в обработку, но не может быть сохранено (storage error)
  - [ ] метрики доступны в `GET /metrics`
  - [ ] **Проверка (pass/fail):** `/metrics` содержит все 3 метрики; integration тест форсит storage error и проверяет рост `ingest_dropped_total`.

- [ ] **6. Сделать:** Реализовать gap события на отказ ingest: `observability_gap.ingest_unavailable`.
  - [ ] при недоступности storage/невозможности принимать ingest возвращается HTTP 503 + `retry_after_ms`
  - [ ] генерируется `observability_gap.ingest_unavailable` (snapshot/stream)
  - [ ] событие содержит evidence_min: причина, error string, queue depth/inflight (если есть), `retry_after_ms`, `trace_id`
  - [ ] событие зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/ingest_unavailable.md`
  - [ ] **Проверка (pass/fail):** induced test переводит storage в ошибку и проверяет 503+`retry_after_ms` + событие в snapshot/stream.

- [ ] **7. Сделать:** Провести chaos тесты ingest (обязательные): kill -9 во время ingest; disk full; восстановление.
  - [ ] chaos: kill -9 Core во время ingest
    - [ ] после рестарта Core: ingest снова принимает события
    - [ ] `ack.upto_seq` остаётся монотонным
  - [ ] chaos: disk full
    - [ ] ingest отвечает 503 + `retry_after_ms`
    - [ ] генерируется `observability_gap.ingest_unavailable` или `observability_gap.storage_disk_full` (оба события определены; выбирается одно и фиксируется)
  - [ ] recovery:
    - [ ] после освобождения места ingest возвращается в нормальный режим без ручной правки данных
  - [ ] **Проверка (pass/fail):** существует документ `docs/ops/ingest_chaos.md` с точными шагами воспроизведения и критериями pass/fail; smoke chaos прогоняется в CI.

## Документация (RU)
- [ ] docs/core/ingest_protocol.md
- [ ] docs/api/errors.md
- [ ] docs/metrics/ingest.md
- [ ] docs/ops/ingest_chaos.md
- [ ] docs/runbooks/ingest_overloaded.md
- [ ] docs/runbooks/ingest_payload_too_large.md
- [ ] docs/runbooks/ingest_unavailable.md

## Тестирование
- [ ] integration: invalid_details + partial accept + ack.upto_seq (шаг 2)
- [ ] load smoke: overload 503 + retry_after_ms + gap event (шаг 3)
- [ ] integration: 413 + retry_after_ms + gap event (шаг 4)
- [ ] integration: storage error → ingest_dropped_total (шаг 5)
- [ ] chaos: kill -9 + disk full + recovery (шаг 7)

## CI gate
- [ ] CI job `ingest-integration` существует и зелёный (шага 2/4/5/6)
- [ ] CI job `ingest-load-smoke` существует и зелёный (шага 3)
- [ ] CI job `ingest-chaos-smoke` существует и зелёный (шага 7)
- [ ] CI job `stage12-docs-gate` существует и запускает `scripts/ci/check_ingest_stage12_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/core/ingest_protocol.md` содержит `ack.upto_seq` и `seq`
    - [ ] `docs/api/errors.md` содержит `invalid_details` и `retry_after_ms`
    - [ ] `docs/metrics/ingest.md` содержит `ingest_dropped_total`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Ingest соответствует контрактам v1: `invalid_details` всегда, `ack.upto_seq` всегда, backpressure реализован (503/413 + retry_after_ms).
- [ ] Метрики ingest присутствуют и проверены тестами.
- [ ] `observability_gap.ingest_overloaded` и `observability_gap.ingest_unavailable` определены, зарегистрированы и имеют runbook.
- [ ] Chaos сценарии воспроизводимы и smoke прогоняются в CI.
- [ ] CI gate Stage 12 зелёный.

