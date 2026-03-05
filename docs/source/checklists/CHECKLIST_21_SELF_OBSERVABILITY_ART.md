A) Полный запрет опциональности:
# CHECKLIST 21 — Self-observability Art
Файл: CHECKLIST_21_SELF_OBSERVABILITY_ART.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение SLO/SLI; изменение метрик; изменение алертов; изменение имен incidents; изменение порогов spool/dlq/source_stale

## Цель
Self-observability однозначна и проверяема: фиксированные internal incidents, фиксированные Grafana dashboards, фиксированные alert tests, и обязательное `observability_gap.metrics_unavailable` при недоступности /metrics.

## Границы
Внутренняя наблюдаемость Art: метрики/алерты/дашборды/инциденты о здоровье самой системы (Core/Agent/Browser Level0).

## Зависимости
- CHECKLIST 01 — Governance/SRE (SLO/SLI, incident rules)
- CHECKLIST 11 — Core Storage
- CHECKLIST 12 — Core Ingest
- CHECKLIST 13 — Core Pipeline
- CHECKLIST 14 — Stream/Snapshot
- CHECKLIST 17 — Agent Spool/Outbox
- CHECKLIST 18 — Agent Receivers
- CHECKLIST 10 — Browser Level0 (если метрики/алерты затрагивают browser)

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать обязательные internal incidents (ровно фиксированный список) и правила их создания.
  - [x] internal incident `core.high_latency`:
    - [x] критерий: p95 `ingest_latency_ms` > 500 (в течение 5 минут)
    - [x] severity: не ниже SEV2
    - [x] action_ref: `docs/runbooks/core_high_latency.md`
  - [x] internal incident `agent.spool_near_full`:
    - [x] критерий: `spool_used_bytes / spool_capacity_bytes >= 0.90` (в течение 1 минуты)
    - [x] severity: не ниже SEV2
    - [x] action_ref: `docs/runbooks/agent_spool_near_full.md`
  - [x] internal incident `dlq_non_empty`:
    - [x] критерий: `dlq_size > 0` (в течение 10 минут)
    - [x] severity: не ниже SEV3
    - [x] action_ref: `docs/runbooks/dlq_non_empty.md`
  - [x] internal incident `source_stale`:
    - [x] критерий: совпадает с Stage 13 (threshold 10 минут) и поднимает internal incident при наличии `observability_gap.source_stale`
    - [x] severity: не ниже SEV2
    - [x] action_ref: `docs/runbooks/source_stale.md`
  - [x] **Проверка (pass/fail):** существует `docs/ops/self_observability.md`, содержит:
    - [x] фиксированный список 4 incidents (имена строго как выше)
    - [x] критерии (числа/окна) для каждого
    - [x] severity и `action_ref` для каждого.

- [x] **2. Сделать:** Добавить Grafana dashboards в репозиторий (фиксированный набор).
  - [x] существует каталог `grafana/`
  - [x] существует файл `grafana/art_core_overview.json`
  - [x] существует файл `grafana/art_agent_overview.json`
  - [x] существует файл `grafana/art_ingest_pipeline.json`
  - [x] каждый dashboard содержит панели минимум:
    - [x] ingest latency (p50/p95)
    - [x] stream lag (p95)
    - [x] spool usage ratio
    - [x] dlq size
    - [x] source stale count
    - [x] metrics scrape success (доля/индикатор)
  - [x] **Проверка (pass/fail):** файлы существуют; экспортированы в JSON и открываются в Grafana без ошибок импорта.

- [x] **3. Сделать:** Реализовать alert tests для обязательных internal incidents (автоматизировано).
  - [x] alert test `agent.spool_near_full`:
    - [x] тест заполняет spool до 90%
    - [x] ожидается: создаётся internal incident/alert `agent.spool_near_full`
  - [x] alert test `dlq_non_empty`:
    - [x] тест создаёт 1 запись в DLQ (по контракту Stage 10/11/17)
    - [x] ожидается: создаётся internal incident/alert `dlq_non_empty` (после 10 минут или через time-sim; выбрать один фиксированный способ и описать)
  - [x] alert test `core.high_latency`:
    - [x] тест искусственно добавляет задержку ingest и поднимает p95 > 500мс на 5 минут (или через time-sim; выбрать один фиксированный способ и описать)
    - [x] ожидается: создаётся internal incident/alert `core.high_latency`
  - [x] alert test `source_stale`:
    - [x] тест симулирует отсутствие событий от source_id > 10 минут
    - [x] ожидается: создаётся internal incident/alert `source_stale`
  - [x] **Проверка (pass/fail):** существует integration suite `self-obs-tests` и она содержит все 4 теста; suite зелёный.

- [x] **4. Сделать:** Реализовать `observability_gap.metrics_unavailable` при недоступности `/metrics`.
  - [x] критерий недоступности фиксирован:
    - [x] network error или HTTP status >= 500 при обращении к `/metrics`
  - [x] `observability_gap.metrics_unavailable` попадает в snapshot/stream и содержит evidence_min:
    - [x] endpoint=`/metrics`
    - [x] error/status
    - [x] retry_count
    - [x] backoff_ms
    - [x] trace_id
  - [x] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/metrics_unavailable.md`
  - [x] **Проверка (pass/fail):** induced test выключает `/metrics` (или подменяет endpoint на 500) и проверяет:
    - [x] генерацию `observability_gap.metrics_unavailable`
    - [x] видимость события в snapshot/stream.

- [x] **5. Сделать:** Добавить CI docs gate для self-observability (минимальная валидация контента).
  - [x] существует `scripts/ci/check_self_observability_stage21_docs.sh`
  - [x] скрипт исполняемый
  - [x] скрипт запускается в CI как blocking job `stage21-docs-gate`
  - [x] скрипт проверяет существование файлов из раздела “Документация (RU)” и dashboards из шага 2
  - [x] скрипт проверяет минимальный контент (grep):
    - [x] `docs/ops/self_observability.md` содержит `core.high_latency`, `agent.spool_near_full`, `dlq_non_empty`, `source_stale`
    - [x] `docs/ops/metrics.md` содержит `/metrics` и перечисление ключевых метрик (ingest_latency_ms/stream_lag_ms/spool_used_bytes/dlq_size)
    - [x] `docs/ops/alerts.md` содержит `p95` и пороги `0.90` и `500`
    - [x] `grafana/art_core_overview.json` содержит строку `ingest` (панели)
  - [x] exit 1 при нарушении любой проверки
  - [x] **Проверка (pass/fail):** CI зелёный; при удалении любого имени incident или dashboard-файла скрипт падает.

## Документация (RU)
- [x] docs/ops/self_observability.md
- [x] docs/ops/metrics.md
- [x] docs/ops/alerts.md
- [x] docs/runbooks/core_high_latency.md
- [x] docs/runbooks/agent_spool_near_full.md
- [x] docs/runbooks/dlq_non_empty.md
- [x] docs/runbooks/metrics_unavailable.md
- [x] grafana/art_core_overview.json
- [x] grafana/art_agent_overview.json
- [x] grafana/art_ingest_pipeline.json
- [x] scripts/ci/check_self_observability_stage21_docs.sh

## Тестирование
- [x] integration: `self-obs-tests` (4 alert tests, шаг 3)
- [x] integration: `self_observability_internal_incidents_cover_required_set` (runtime e2e по 4 обязательным internal incidents)
- [x] induced: `/metrics` unavailable → `observability_gap.metrics_unavailable` (шаг 4)

## CI gate
- [x] CI job `self-obs-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `stage21-docs-gate` существует и запускается на PR в main; job зелёный

## DoD
- [x] Список internal incidents фиксирован (4 шт), критерии/пороги/окна заданы числами и задокументированы.
- [x] Grafana dashboards добавлены и соответствуют минимальному набору панелей.
- [x] Alert tests автоматизированы и зелёные (включая runtime e2e по 4 internal incidents).
- [x] `observability_gap.metrics_unavailable` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [x] CI gate Stage 21 зелёный.
