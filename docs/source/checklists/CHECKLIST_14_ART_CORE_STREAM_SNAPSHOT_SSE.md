A) Полный запрет опциональности:
# CHECKLIST 14 — Art Core Stream/Snapshot v1 (SSE)
Файл: CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение retention; изменение SSE поведения; изменение нагрузочных целей; изменение контракта cursors/Last-Event-ID
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
SSE однозначен и проверяем: Last-Event-ID too old → snapshot+new_cursor; gzip обязателен при Accept-Encoding:gzip; нагрузочные цели фиксированы (10k events, 1000 subs); деградации stream порождают `observability_gap.stream_unavailable` и `observability_gap.stream_lag`.

## Границы
Только API выдачи: `/api/v1/snapshot` и `/api/v1/stream` (SSE). Ingest/pipeline/storage — в других этапах.

## Зависимости
- CHECKLIST 13 — Art Core Pipeline v1 (rules/enrich/correlation)
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 11 — Art Core Storage v1 (SQLite)
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, runbooks)

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать модель cursor/Last-Event-ID и политику “too old → snapshot”.
  - [x] Stream использует `Last-Event-ID` как cursor (строка) и интерпретирует его как `seq` (целое) — одно фиксированное решение
  - [x] Retention для stream фиксирован: 24 часа (86400000 мс)
  - [x] Если `Last-Event-ID` старше retention (seq < min_retained_seq):
    - [x] сервер возвращает snapshot (тот же формат, что `/api/v1/snapshot`)
    - [x] сервер возвращает `new_cursor` (строка) в заголовке `X-Stream-Cursor`
    - [x] клиент после snapshot обязан переподключиться к `/api/v1/stream` с `Last-Event-ID=new_cursor`
  - [x] Если `Last-Event-ID` валиден:
    - [x] сервер продолжает SSE stream “с этого cursor”
  - [x] **Проверка (pass/fail):** существует `docs/api/stream.md` и он содержит правила выше с примером “too old” (request/response headers + пример new_cursor) и пример “валидный cursor”.

- [x] **2. Сделать:** Реализовать поведение “too old → snapshot+new_cursor” и покрыть integration test.
  - [x] Сервер вычисляет `min_retained_seq` (минимальный доступный seq в retention window)
  - [x] При `Last-Event-ID < min_retained_seq`:
    - [x] возвращается snapshot (HTTP 200)
    - [x] присутствует заголовок `X-Stream-Cursor` (новый cursor)
    - [x] тело ответа соответствует snapshot контракту
  - [x] При `Last-Event-ID >= min_retained_seq`:
    - [x] возвращается SSE stream (Content-Type: `text/event-stream`)
    - [x] события идут монотонно по `id:` (id = seq)
  - [x] **Проверка (pass/fail):** integration test форсит “too old” и проверяет:
    - [x] HTTP 200
    - [x] `X-Stream-Cursor` присутствует
    - [x] тело соответствует snapshot контракту
    и второй тест проверяет валидный cursor → SSE stream с `Content-Type: text/event-stream`.

- [x] **3. Сделать:** Реализовать SSE gzip при `Accept-Encoding: gzip`.
  - [x] если клиент отправляет `Accept-Encoding: gzip`, сервер отвечает `Content-Encoding: gzip`
  - [x] gzip применяется только к stream-каналу (SSE)
  - [x] `Cache-Control: no-cache` установлен
  - [x] **Проверка (pass/fail):** integration test делает запрос к `/api/v1/stream` с `Accept-Encoding: gzip` и проверяет:
    - [x] `Content-Encoding: gzip`
    - [x] `Content-Type: text/event-stream`
    - [x] поток реально декомпрессится клиентом и читается как SSE.

- [x] **4. Сделать:** Реализовать деградации stream как gap события: `observability_gap.stream_unavailable` и `observability_gap.stream_lag`.
  - [x] `observability_gap.stream_unavailable` генерируется при:
    - [x] невозможности открыть stream (ошибка storage/внутренний error) или принудительном закрытии из-за внутренних ошибок
  - [x] `observability_gap.stream_lag` генерируется при:
    - [x] lag по stream превышает 5000 мс (threshold фиксирован)
  - [x] Оба события попадают в snapshot/stream и содержат evidence_min:
    - [x] endpoint (`/api/v1/stream`)
    - [x] reason (строка)
    - [x] `lag_ms` (для stream_lag)
    - [x] `subscriber_count`
    - [x] `trace_id`
  - [x] Оба события зарегистрированы в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/stream_unavailable.md` и `docs/runbooks/stream_lag.md`
  - [x] **Проверка (pass/fail):** induced tests:
    - [x] симулируют ошибку открытия stream → появляется `observability_gap.stream_unavailable`
    - [x] симулируют lag>5000ms → появляется `observability_gap.stream_lag`.

- [x] **5. Сделать:** Провести нагрузочный тест SSE “10k events” и зафиксировать критерии pass/fail.
  - [x] сценарий: публикуется 10000 событий; 1 подписчик читает stream до конца
  - [x] критерии pass/fail фиксированы:
    - [x] все 10000 событий получены и порядок `id:` монотонен
    - [x] ошибок разрыва соединения нет
    - [x] суммарное время теста ≤ 120 секунд
  - [x] **Проверка (pass/fail):** существует отчёт `docs/perf/stream_10k_events.md`, содержит:
    - [x] команду запуска теста
    - [x] окружение (CPU/RAM)
    - [x] результаты (время, ошибки, count)
    - [x] явный вывод pass/fail по критериям.

- [x] **6. Сделать:** Провести нагрузочный тест SSE “1000 subscribers” и зафиксировать критерии pass/fail.
  - [x] сценарий: 1000 одновременных подписчиков держат stream 60 секунд
  - [x] критерии pass/fail фиксированы:
    - [x] CPU процесса Core ≤ 80% (среднее за тест)
    - [x] RAM процесса Core ≤ 1024 MiB (пик за тест)
    - [x] не более 1% разрывов соединения
    - [x] `stream_lag_ms` p95 ≤ 2000 мс
  - [x] **Проверка (pass/fail):** существует отчёт `docs/perf/stream_1000_subscribers.md`, содержит:
    - [x] команду запуска
    - [x] окружение (CPU/RAM)
    - [x] метрики (CPU/RAM/разрывы/lag)
    - [x] явный вывод pass/fail по критериям.

## Документация (RU)
- [x] docs/api/stream.md
- [x] docs/api/snapshot.md
- [x] docs/metrics/stream.md
- [x] docs/runbooks/stream_unavailable.md
- [x] docs/runbooks/stream_lag.md
- [x] docs/perf/stream_10k_events.md
- [x] docs/perf/stream_1000_subscribers.md

## Тестирование
- [x] integration: “too old → snapshot+X-Stream-Cursor” (шаг 2)
- [x] integration: SSE gzip (шаг 3)
- [x] induced: stream_unavailable + stream_lag (шаг 4)
- [x] load: 10k events (шаг 5)
- [x] load: 1000 subs (шаг 6)
- [x] long soak artifacts: `scripts/tests/stream_soak_with_artifacts.sh` + workflow `.github/workflows/stage14-soak-artifacts.yml`

## CI gate
- [x] CI job `stream-integration` существует и зелёный (шага 2/3/4)
- [x] CI job `stream-load-smoke` существует и зелёный (smoke подмножество шага 5 или 6; один фиксированный smoke сценарий: 1000 events + 50 subs)
- [x] Отдельный workflow `stage14-soak-artifacts` публикует артефакты long soak (`stream_10k_events.log`, `stream_1000_subscribers_60s.log`, `summary.json`)
- [x] CI job `stage14-docs-gate` существует и запускает `scripts/ci/check_stream_stage14_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/api/stream.md` содержит `Last-Event-ID` и `X-Stream-Cursor` и `86400000`
    - [x] `docs/metrics/stream.md` содержит `stream_lag_ms`
    - [x] runbooks содержат `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Политика cursor/Last-Event-ID определена и реализована: too old → snapshot + new_cursor.
- [x] SSE gzip реализован и покрыт integration test.
- [x] `observability_gap.stream_unavailable` и `observability_gap.stream_lag` реализованы, зарегистрированы и имеют runbook.
- [x] Нагрузочные тесты выполнены и имеют отчёты с pass/fail критериями.
- [x] CI gate Stage 14 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
