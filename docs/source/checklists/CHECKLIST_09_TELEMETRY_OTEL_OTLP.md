A) Полный запрет опциональности:
# CHECKLIST 09 — Telemetry alignment (OTel/OTLP)
Файл: CHECKLIST_09_TELEMETRY_OTEL_OTLP.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (telemetry pass)  
Триггер пересмотра: изменение OTel mapping; изменение лимитов OTLP; изменение схем RawEvent/ingest; изменение политики backpressure
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Согласовать OTLP→RawEvent и сделать поведение детерминированным: unknown attrs → `payload.otel_attributes`, строгий severity mapping, фиксированные OTLP rate-limits, backpressure ответы с `retry_after_ms`, и обязательное событие `observability_gap.otlp_rate_limited`.

## Границы
Только alignment, контракты и тесты телеметрии (OTel/OTLP). Реализация ingestion/хранилища описывается в других этапах.

## Зависимости
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Статус перепроверки
- Документация, тесты и CI gate перепроверены по факту кода и workflow.
- Пункты этапа закрыты по результатам проверок.

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать mapping: unknown OTel attributes → `payload.otel_attributes`.
  - [ ] все неизвестные атрибуты OTel попадают в `payload.otel_attributes` без потерь
  - [ ] ключи атрибутов сохраняются в исходном виде (строки)
  - [ ] значения приводятся к JSON-совместимому виду:
    - [ ] string → string
    - [ ] bool → bool
    - [ ] int/double → number
    - [ ] array → array (элементы приведены по тем же правилам)
    - [ ] bytes → base64 string
  - [ ] конфликт имён: если ключ уже занят фиксированным полем RawEvent/ctx — ключ в `payload.otel_attributes` сохраняется как `otel.<key>`
  - [ ] **Проверка (pass/fail):** существует `docs/telemetry/otel_mapping.md`, содержит все правила выше в явном виде и включает минимум 1 пример входа/выхода.

- [ ] **2. Сделать:** Зафиксировать severity mapping OTel→RawEvent.severity и покрыть тестами.
  - [ ] OTel DEBUG → RawEvent.severity=debug
  - [ ] OTel INFO → RawEvent.severity=info
  - [ ] OTel WARN → RawEvent.severity=warn
  - [ ] OTel ERROR → RawEvent.severity=error
  - [ ] OTel FATAL → RawEvent.severity=fatal
  - [ ] для неизвестного уровня severity: RawEvent.severity=info и добавляется метка `payload.otel_severity_unknown=true`
  - [ ] **Проверка (pass/fail):** существует test suite `test-telemetry` и он содержит 5 тестов для DEBUG/INFO/WARN/ERROR/FATAL + 1 тест для unknown severity; suite зелёный.

- [ ] **3. Сделать:** Зафиксировать OTLP rate limits (дефолты) и правила применения.
  - [ ] `max_events_per_sec=200`
  - [ ] `burst=400`
  - [ ] `max_batch_events=200`
  - [ ] `max_size_bytes=524288`
  - [ ] лимиты применяются на входе OTLP receiver до преобразования в RawEvent
  - [ ] принимается только OTLP logs (одно фиксированное решение)
  - [ ] **Проверка (pass/fail):** `docs/telemetry/otlp_receiver.md` содержит значения и правила применения лимитов.

- [ ] **4. Сделать:** При превышении лимитов: backpressure + `retry_after_ms` + событие `observability_gap.otlp_rate_limited`.
  - [ ] при превышении rate limit возвращается HTTP 429
  - [ ] при перегрузке/недоступности возвращается HTTP 503
  - [ ] при превышении размера/батча возвращается HTTP 413
  - [ ] во всех случаях backpressure-ответ содержит `retry_after_ms` (число >= 0)
  - [ ] при любом срабатывании лимита генерируется `observability_gap.otlp_rate_limited` и попадает в snapshot/stream
  - [ ] `observability_gap.otlp_rate_limited` содержит evidence_min:
    - [ ] лимит, который сработал (какой именно)
    - [ ] текущее значение (факт превышения)
    - [ ] `retry_after_ms`
    - [ ] endpoint
    - [ ] `trace_id`
  - [ ] событие зарегистрировано в `docs/governance/observability_gap_registry.md` (Stage 01) с:
    - [ ] `incident_rule` имеет строгое ограничение: `create_incident_min_sev2` (или более строгий, т.е. SEV1/SEV0), но не слабее SEV2
    - [ ] `action_ref` → `docs/runbooks/otlp_rate_limited.md`
  - [ ] **Проверка (pass/fail):** существует integration test, который форсит превышение лимита и проверяет:
    - [ ] HTTP статус (429/503/413)
    - [ ] наличие `retry_after_ms`
    - [ ] появление `observability_gap.otlp_rate_limited` в snapshot/stream.

- [ ] **5. Сделать:** Зафиксировать единый документ лимитов.
  - [ ] `docs/telemetry/limits.md` существует
  - [ ] содержит таблицу лимитов OTLP с точными значениями (из шага 3)
  - [ ] содержит ссылку на `docs/telemetry/otlp_receiver.md` и `docs/telemetry/otel_mapping.md`
  - [ ] **Проверка (pass/fail):** файл существует и содержит таблицу лимитов + ссылки.

## Документация (RU)
- [ ] docs/telemetry/otel_mapping.md
- [ ] docs/telemetry/otlp_receiver.md
- [ ] docs/telemetry/limits.md
- [ ] docs/runbooks/otlp_rate_limited.md

## Тестирование
- [ ] unit: mapping unknown attrs → `payload.otel_attributes` (типизация значений + bytes→base64 + конфликт имён)
- [ ] unit: severity mapping DEBUG/INFO/WARN/ERROR/FATAL + unknown severity
- [ ] integration: rate-limit backpressure (429/503/413) + `retry_after_ms`
- [ ] integration: генерация `observability_gap.otlp_rate_limited` и видимость в snapshot/stream
- [ ] runtime integration: `POST /otlp/v1/logs` покрыт тестами `otlp_logs_*` + `scripts/tests/otlp_runtime_integration.sh`

## CI gate
- [ ] CI job `test-telemetry` существует и запускается на PR в main
- [ ] `test-telemetry` включает unit+integration тесты этого этапа и runtime OTLP integration (`scripts/tests/otlp_runtime_integration.sh`) и зелёный
- [ ] CI job `telemetry-docs-gate` существует и запускается на PR в main
- [ ] `telemetry-docs-gate` запускает скрипт `scripts/ci/check_telemetry_stage09_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/telemetry/otel_mapping.md` содержит строки `payload.otel_attributes`, `bytes → base64`, `otel.<key>`
    - [ ] `docs/telemetry/otlp_receiver.md` содержит `max_events_per_sec=200`, `burst=400`, `max_batch_events=200`, `max_size_bytes=524288`
    - [ ] `docs/telemetry/limits.md` содержит `max_events_per_sec`, `max_size_bytes`
    - [ ] `docs/runbooks/otlp_rate_limited.md` содержит `mitigations` и `verification`
  - [ ] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [ ] OTel mapping определён и задокументирован.
- [ ] Severity mapping определён и покрыт тестами.
- [ ] OTLP лимиты фиксированы, задокументированы и проверяемы.
- [ ] Backpressure + `retry_after_ms` реализованы и покрыты интеграционным тестом.
- [ ] `observability_gap.otlp_rate_limited` определён, зарегистрирован с `incident_rule` не слабее `create_incident_min_sev2`, и имеет runbook; событие проверяется в integration test.
- [ ] CI gate зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
