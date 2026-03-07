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

- [ ] **1. Сделать:** Зафиксировать модель cursor/Last-Event-ID и политику “too old → snapshot”.
  - [ ] Stream использует `Last-Event-ID` как cursor (строка) и интерпретирует его как `seq` (целое) — одно фиксированное решение
  - [ ] Retention для stream фиксирован: 24 часа (86400000 мс)
  - [ ] Если `Last-Event-ID` старше retention (seq < min_retained_seq):
    - [ ] сервер возвращает snapshot (тот же формат, что `/api/v1/snapshot`)
    - [ ] сервер возвращает `new_cursor` (строка) в заголовке `X-Stream-Cursor`
    - [ ] клиент после snapshot обязан переподключиться к `/api/v1/stream` с `Last-Event-ID=new_cursor`
  - [ ] Если `Last-Event-ID` валиден:
    - [ ] сервер продолжает SSE stream “с этого cursor”
  - [ ] **Проверка (pass/fail):** существует `docs/api/stream.md` и он содержит правила выше с примером “too old” (request/response headers + пример new_cursor) и пример “валидный cursor”.

- [ ] **2. Сделать:** Реализовать поведение “too old → snapshot+new_cursor” и покрыть integration test.
  - [ ] Сервер вычисляет `min_retained_seq` (минимальный доступный seq в retention window)
  - [ ] При `Last-Event-ID < min_retained_seq`:
    - [ ] возвращается snapshot (HTTP 200)
    - [ ] присутствует заголовок `X-Stream-Cursor` (новый cursor)
    - [ ] тело ответа соответствует snapshot контракту
  - [ ] При `Last-Event-ID >= min_retained_seq`:
    - [ ] возвращается SSE stream (Content-Type: `text/event-stream`)
    - [ ] события идут монотонно по `id:` (id = seq)
  - [ ] **Проверка (pass/fail):** integration test форсит “too old” и проверяет:
    - [ ] HTTP 200
    - [ ] `X-Stream-Cursor` присутствует
    - [ ] тело соответствует snapshot контракту
    и второй тест проверяет валидный cursor → SSE stream с `Content-Type: text/event-stream`.

- [ ] **3. Сделать:** Реализовать SSE gzip при `Accept-Encoding: gzip`.
  - [ ] если клиент отправляет `Accept-Encoding: gzip`, сервер отвечает `Content-Encoding: gzip`
  - [ ] gzip применяется только к stream-каналу (SSE)
  - [ ] `Cache-Control: no-cache` установлен
  - [ ] **Проверка (pass/fail):** integration test делает запрос к `/api/v1/stream` с `Accept-Encoding: gzip` и проверяет:
    - [ ] `Content-Encoding: gzip`
    - [ ] `Content-Type: text/event-stream`
    - [ ] поток реально декомпрессится клиентом и читается как SSE.

- [ ] **4. Сделать:** Реализовать деградации stream как gap события: `observability_gap.stream_unavailable` и `observability_gap.stream_lag`.
  - [ ] `observability_gap.stream_unavailable` генерируется при:
    - [ ] невозможности открыть stream (ошибка storage/внутренний error) или принудительном закрытии из-за внутренних ошибок
  - [ ] `observability_gap.stream_lag` генерируется при:
    - [ ] lag по stream превышает 5000 мс (threshold фиксирован)
  - [ ] Оба события попадают в snapshot/stream и содержат evidence_min:
    - [ ] endpoint (`/api/v1/stream`)
    - [ ] reason (строка)
    - [ ] `lag_ms` (для stream_lag)
    - [ ] `subscriber_count`
    - [ ] `trace_id`
  - [ ] Оба события зарегистрированы в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/stream_unavailable.md` и `docs/runbooks/stream_lag.md`
  - [ ] **Проверка (pass/fail):** induced tests:
    - [ ] симулируют ошибку открытия stream → появляется `observability_gap.stream_unavailable`
    - [ ] симулируют lag>5000ms → появляется `observability_gap.stream_lag`.

- [ ] **5. Сделать:** Провести нагрузочный тест SSE “10k events” и зафиксировать критерии pass/fail.
  - [ ] сценарий: публикуется 10000 событий; 1 подписчик читает stream до конца
  - [ ] критерии pass/fail фиксированы:
    - [ ] все 10000 событий получены и порядок `id:` монотонен
    - [ ] ошибок разрыва соединения нет
    - [ ] суммарное время теста ≤ 120 секунд
  - [ ] **Проверка (pass/fail):** существует отчёт `docs/perf/stream_10k_events.md`, содержит:
    - [ ] команду запуска теста
    - [ ] окружение (CPU/RAM)
    - [ ] результаты (время, ошибки, count)
    - [ ] явный вывод pass/fail по критериям.

- [ ] **6. Сделать:** Провести нагрузочный тест SSE “1000 subscribers” и зафиксировать критерии pass/fail.
  - [ ] сценарий: 1000 одновременных подписчиков держат stream 60 секунд
  - [ ] критерии pass/fail фиксированы:
    - [ ] CPU процесса Core ≤ 80% (среднее за тест)
    - [ ] RAM процесса Core ≤ 1024 MiB (пик за тест)
    - [ ] не более 1% разрывов соединения
    - [ ] `stream_lag_ms` p95 ≤ 2000 мс
  - [ ] **Проверка (pass/fail):** существует отчёт `docs/perf/stream_1000_subscribers.md`, содержит:
    - [ ] команду запуска
    - [ ] окружение (CPU/RAM)
    - [ ] метрики (CPU/RAM/разрывы/lag)
    - [ ] явный вывод pass/fail по критериям.

## Документация (RU)
- [ ] docs/api/stream.md
- [ ] docs/api/snapshot.md
- [ ] docs/metrics/stream.md
- [ ] docs/runbooks/stream_unavailable.md
- [ ] docs/runbooks/stream_lag.md
- [ ] docs/perf/stream_10k_events.md
- [ ] docs/perf/stream_1000_subscribers.md

## Тестирование
- [ ] integration: “too old → snapshot+X-Stream-Cursor” (шаг 2)
- [ ] integration: SSE gzip (шаг 3)
- [ ] induced: stream_unavailable + stream_lag (шаг 4)
- [ ] load: 10k events (шаг 5)
- [ ] load: 1000 subs (шаг 6)
- [ ] long soak artifacts: `scripts/tests/stream_soak_with_artifacts.sh` + workflow `.github/workflows/stage14-soak-artifacts.yml`

## CI gate
- [ ] CI job `stream-integration` существует и зелёный (шага 2/3/4)
- [ ] CI job `stream-load-smoke` существует и зелёный (smoke подмножество шага 5 или 6; один фиксированный smoke сценарий: 1000 events + 50 subs)
- [ ] Отдельный workflow `stage14-soak-artifacts` публикует артефакты long soak (`stream_10k_events.log`, `stream_1000_subscribers_60s.log`, `summary.json`)
- [ ] CI job `stage14-docs-gate` существует и запускает `scripts/ci/check_stream_stage14_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/api/stream.md` содержит `Last-Event-ID` и `X-Stream-Cursor` и `86400000`
    - [ ] `docs/metrics/stream.md` содержит `stream_lag_ms`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Политика cursor/Last-Event-ID определена и реализована: too old → snapshot + new_cursor.
- [ ] SSE gzip реализован и покрыт integration test.
- [ ] `observability_gap.stream_unavailable` и `observability_gap.stream_lag` реализованы, зарегистрированы и имеют runbook.
- [ ] Нагрузочные тесты выполнены и имеют отчёты с pass/fail критериями.
- [ ] CI gate Stage 14 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
