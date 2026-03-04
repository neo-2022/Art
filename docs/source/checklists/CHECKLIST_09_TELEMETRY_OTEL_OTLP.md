A) Полный запрет опциональности:
# CHECKLIST 09 — Telemetry alignment (OTel/OTLP)
Файл: CHECKLIST_09_TELEMETRY_OTEL_OTLP.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение OTel mapping; изменение лимитов OTLP; изменение схем RawEvent/ingest; изменение политики backpressure

## Цель
Согласовать OTLP→RawEvent и сделать поведение детерминированным: unknown attrs → `payload.otel_attributes`, строгий severity mapping, фиксированные OTLP rate-limits, backpressure ответы с `retry_after_ms`, и обязательное событие `observability_gap.otlp_rate_limited`.

## Границы
Только alignment, контракты и тесты телеметрии (OTel/OTLP). Реализация ingestion/хранилища описывается в других этапах.

## Зависимости
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать mapping: unknown OTel attributes → `payload.otel_attributes`.
  - [x] все неизвестные атрибуты OTel попадают в `payload.otel_attributes` без потерь
  - [x] ключи атрибутов сохраняются в исходном виде (строки)
  - [x] значения приводятся к JSON-совместимому виду:
    - [x] string → string
    - [x] bool → bool
    - [x] int/double → number
    - [x] array → array (элементы приведены по тем же правилам)
    - [x] bytes → base64 string
  - [x] конфликт имён: если ключ уже занят фиксированным полем RawEvent/ctx — ключ в `payload.otel_attributes` сохраняется как `otel.<key>`
  - [x] **Проверка (pass/fail):** существует `docs/telemetry/otel_mapping.md`, содержит все правила выше в явном виде и включает минимум 1 пример входа/выхода.

- [x] **2. Сделать:** Зафиксировать severity mapping OTel→RawEvent.severity и покрыть тестами.
  - [x] OTel DEBUG → RawEvent.severity=debug
  - [x] OTel INFO → RawEvent.severity=info
  - [x] OTel WARN → RawEvent.severity=warn
  - [x] OTel ERROR → RawEvent.severity=error
  - [x] OTel FATAL → RawEvent.severity=fatal
  - [x] для неизвестного уровня severity: RawEvent.severity=info и добавляется метка `payload.otel_severity_unknown=true`
  - [x] **Проверка (pass/fail):** существует test suite `test-telemetry` и он содержит 5 тестов для DEBUG/INFO/WARN/ERROR/FATAL + 1 тест для unknown severity; suite зелёный.

- [x] **3. Сделать:** Зафиксировать OTLP rate limits (дефолты) и правила применения.
  - [x] `max_events_per_sec=200`
  - [x] `burst=400`
  - [x] `max_batch_events=200`
  - [x] `max_size_bytes=524288`
  - [x] лимиты применяются на входе OTLP receiver до преобразования в RawEvent
  - [x] принимается только OTLP logs (одно фиксированное решение)
  - [x] **Проверка (pass/fail):** `docs/telemetry/otlp_receiver.md` содержит значения и правила применения лимитов.

- [x] **4. Сделать:** При превышении лимитов: backpressure + `retry_after_ms` + событие `observability_gap.otlp_rate_limited`.
  - [x] при превышении rate limit возвращается HTTP 429
  - [x] при перегрузке/недоступности возвращается HTTP 503
  - [x] при превышении размера/батча возвращается HTTP 413
  - [x] во всех случаях backpressure-ответ содержит `retry_after_ms` (число >= 0)
  - [x] при любом срабатывании лимита генерируется `observability_gap.otlp_rate_limited` и попадает в snapshot/stream
  - [x] `observability_gap.otlp_rate_limited` содержит evidence_min:
    - [x] лимит, который сработал (какой именно)
    - [x] текущее значение (факт превышения)
    - [x] `retry_after_ms`
    - [x] endpoint
    - [x] `trace_id`
  - [x] событие зарегистрировано в `docs/governance/observability_gap_registry.md` (Stage 01) с:
    - [x] `incident_rule` имеет строгое ограничение: `create_incident_min_sev2` (или более строгий, т.е. SEV1/SEV0), но не слабее SEV2
    - [x] `action_ref` → `docs/runbooks/otlp_rate_limited.md`
  - [x] **Проверка (pass/fail):** существует integration test, который форсит превышение лимита и проверяет:
    - [x] HTTP статус (429/503/413)
    - [x] наличие `retry_after_ms`
    - [x] появление `observability_gap.otlp_rate_limited` в snapshot/stream.

- [x] **5. Сделать:** Зафиксировать единый документ лимитов.
  - [x] `docs/telemetry/limits.md` существует
  - [x] содержит таблицу лимитов OTLP с точными значениями (из шага 3)
  - [x] содержит ссылку на `docs/telemetry/otlp_receiver.md` и `docs/telemetry/otel_mapping.md`
  - [x] **Проверка (pass/fail):** файл существует и содержит таблицу лимитов + ссылки.

## Документация (RU)
- [x] docs/telemetry/otel_mapping.md
- [x] docs/telemetry/otlp_receiver.md
- [x] docs/telemetry/limits.md
- [x] docs/runbooks/otlp_rate_limited.md

## Тестирование
- [x] unit: mapping unknown attrs → `payload.otel_attributes` (типизация значений + bytes→base64 + конфликт имён)
- [x] unit: severity mapping DEBUG/INFO/WARN/ERROR/FATAL + unknown severity
- [x] integration: rate-limit backpressure (429/503/413) + `retry_after_ms`
- [x] integration: генерация `observability_gap.otlp_rate_limited` и видимость в snapshot/stream

## CI gate
- [x] CI job `test-telemetry` существует и запускается на PR в main
- [x] `test-telemetry` включает unit+integration тесты этого этапа и зелёный
- [x] CI job `telemetry-docs-gate` существует и запускается на PR в main
- [x] `telemetry-docs-gate` запускает скрипт `scripts/ci/check_telemetry_stage09_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/telemetry/otel_mapping.md` содержит строки `payload.otel_attributes`, `bytes → base64`, `otel.<key>`
    - [x] `docs/telemetry/otlp_receiver.md` содержит `max_events_per_sec=200`, `burst=400`, `max_batch_events=200`, `max_size_bytes=524288`
    - [x] `docs/telemetry/limits.md` содержит `max_events_per_sec`, `max_size_bytes`
    - [x] `docs/runbooks/otlp_rate_limited.md` содержит `mitigations` и `verification`
  - [x] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [x] OTel mapping определён и задокументирован.
- [x] Severity mapping определён и покрыт тестами.
- [x] OTLP лимиты фиксированы, задокументированы и проверяемы.
- [x] Backpressure + `retry_after_ms` реализованы и покрыты интеграционным тестом.
- [x] `observability_gap.otlp_rate_limited` определён, зарегистрирован с `incident_rule` не слабее `create_incident_min_sev2`, и имеет runbook; событие проверяется в integration test.
- [x] CI gate зелёный.

