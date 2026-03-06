A) Полный запрет опциональности:
# CHECKLIST 21 — Self-observability Art
Файл: CHECKLIST_21_SELF_OBSERVABILITY_ART.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение SLO/SLI; изменение метрик; изменение алертов; изменение имен incidents; изменение порогов spool/dlq/source_stale
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

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

- [ ] **1. Сделать:** Зафиксировать обязательные internal incidents (ровно фиксированный список) и правила их создания.
  - [ ] internal incident `core.high_latency`:
    - [ ] критерий: p95 `ingest_latency_ms` > 500 (в течение 5 минут)
    - [ ] severity: не ниже SEV2
    - [ ] action_ref: `docs/runbooks/core_high_latency.md`
  - [ ] internal incident `agent.spool_near_full`:
    - [ ] критерий: `spool_used_bytes / spool_capacity_bytes >= 0.90` (в течение 1 минуты)
    - [ ] severity: не ниже SEV2
    - [ ] action_ref: `docs/runbooks/agent_spool_near_full.md`
  - [ ] internal incident `dlq_non_empty`:
    - [ ] критерий: `dlq_size > 0` (в течение 10 минут)
    - [ ] severity: не ниже SEV3
    - [ ] action_ref: `docs/runbooks/dlq_non_empty.md`
  - [ ] internal incident `source_stale`:
    - [ ] критерий: совпадает с Stage 13 (threshold 10 минут) и поднимает internal incident при наличии `observability_gap.source_stale`
    - [ ] severity: не ниже SEV2
    - [ ] action_ref: `docs/runbooks/source_stale.md`
  - [ ] **Проверка (pass/fail):** существует `docs/ops/self_observability.md`, содержит:
    - [ ] фиксированный список 4 incidents (имена строго как выше)
    - [ ] критерии (числа/окна) для каждого
    - [ ] severity и `action_ref` для каждого.

- [ ] **2. Сделать:** Добавить Grafana dashboards в репозиторий (фиксированный набор).
  - [ ] существует каталог `grafana/`
  - [ ] существует файл `grafana/art_core_overview.json`
  - [ ] существует файл `grafana/art_agent_overview.json`
  - [ ] существует файл `grafana/art_ingest_pipeline.json`
  - [ ] каждый dashboard содержит панели минимум:
    - [ ] ingest latency (p50/p95)
    - [ ] stream lag (p95)
    - [ ] spool usage ratio
    - [ ] dlq size
    - [ ] source stale count
    - [ ] metrics scrape success (доля/индикатор)
  - [ ] **Проверка (pass/fail):** файлы существуют; экспортированы в JSON и открываются в Grafana без ошибок импорта.

- [ ] **3. Сделать:** Реализовать alert tests для обязательных internal incidents (автоматизировано).
  - [ ] alert test `agent.spool_near_full`:
    - [ ] тест заполняет spool до 90%
    - [ ] ожидается: создаётся internal incident/alert `agent.spool_near_full`
  - [ ] alert test `dlq_non_empty`:
    - [ ] тест создаёт 1 запись в DLQ (по контракту Stage 10/11/17)
    - [ ] ожидается: создаётся internal incident/alert `dlq_non_empty` (после 10 минут или через time-sim; выбрать один фиксированный способ и описать)
  - [ ] alert test `core.high_latency`:
    - [ ] тест искусственно добавляет задержку ingest и поднимает p95 > 500мс на 5 минут (или через time-sim; выбрать один фиксированный способ и описать)
    - [ ] ожидается: создаётся internal incident/alert `core.high_latency`
  - [ ] alert test `source_stale`:
    - [ ] тест симулирует отсутствие событий от source_id > 10 минут
    - [ ] ожидается: создаётся internal incident/alert `source_stale`
  - [ ] **Проверка (pass/fail):** существует integration suite `self-obs-tests` и она содержит все 4 теста; suite зелёный.

- [ ] **4. Сделать:** Реализовать `observability_gap.metrics_unavailable` при недоступности `/metrics`.
  - [ ] критерий недоступности фиксирован:
    - [ ] network error или HTTP status >= 500 при обращении к `/metrics`
  - [ ] `observability_gap.metrics_unavailable` попадает в snapshot/stream и содержит evidence_min:
    - [ ] endpoint=`/metrics`
    - [ ] error/status
    - [ ] retry_count
    - [ ] backoff_ms
    - [ ] trace_id
  - [ ] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/metrics_unavailable.md`
  - [ ] **Проверка (pass/fail):** induced test выключает `/metrics` (или подменяет endpoint на 500) и проверяет:
    - [ ] генерацию `observability_gap.metrics_unavailable`
    - [ ] видимость события в snapshot/stream.

- [ ] **5. Сделать:** Добавить CI docs gate для self-observability (минимальная валидация контента).
  - [ ] существует `scripts/ci/check_self_observability_stage21_docs.sh`
  - [ ] скрипт исполняемый
  - [ ] скрипт запускается в CI как blocking job `stage21-docs-gate`
  - [ ] скрипт проверяет существование файлов из раздела “Документация (RU)” и dashboards из шага 2
  - [ ] скрипт проверяет минимальный контент (grep):
    - [ ] `docs/ops/self_observability.md` содержит `core.high_latency`, `agent.spool_near_full`, `dlq_non_empty`, `source_stale`
    - [ ] `docs/ops/metrics.md` содержит `/metrics` и перечисление ключевых метрик (ingest_latency_ms/stream_lag_ms/spool_used_bytes/dlq_size)
    - [ ] `docs/ops/alerts.md` содержит `p95` и пороги `0.90` и `500`
    - [ ] `grafana/art_core_overview.json` содержит строку `ingest` (панели)
  - [ ] exit 1 при нарушении любой проверки
  - [ ] **Проверка (pass/fail):** CI зелёный; при удалении любого имени incident или dashboard-файла скрипт падает.

## Документация (RU)
- [ ] docs/ops/self_observability.md
- [ ] docs/ops/metrics.md
- [ ] docs/ops/alerts.md
- [ ] docs/runbooks/core_high_latency.md
- [ ] docs/runbooks/agent_spool_near_full.md
- [ ] docs/runbooks/dlq_non_empty.md
- [ ] docs/runbooks/metrics_unavailable.md
- [ ] grafana/art_core_overview.json
- [ ] grafana/art_agent_overview.json
- [ ] grafana/art_ingest_pipeline.json
- [ ] scripts/ci/check_self_observability_stage21_docs.sh

## Тестирование
- [ ] integration: `self-obs-tests` (4 alert tests, шаг 3)
- [ ] integration: `self_observability_internal_incidents_cover_required_set` (runtime e2e по 4 обязательным internal incidents)
- [ ] induced: `/metrics` unavailable → `observability_gap.metrics_unavailable` (шаг 4)

## CI gate
- [ ] CI job `self-obs-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage21-docs-gate` существует и запускается на PR в main; job зелёный

## DoD
- [ ] Список internal incidents фиксирован (4 шт), критерии/пороги/окна заданы числами и задокументированы.
- [ ] Grafana dashboards добавлены и соответствуют минимальному набору панелей.
- [ ] Alert tests автоматизированы и зелёные (включая runtime e2e по 4 internal incidents).
- [ ] `observability_gap.metrics_unavailable` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [ ] CI gate Stage 21 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
