A) Полный запрет опциональности:
# CHECKLIST 13 — Art Core Pipeline v1 (rules/enrich/correlation)
Файл: CHECKLIST_13_ART_CORE_PIPELINE_ENRICH_RULES.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (pass)  
Триггер пересмотра: изменение rules/enrich; изменение Incident схемы; изменение correlation модели; изменение политики security тестов шаблонов
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Pipeline однозначен и проверяем: correlation переносится в Incident; collision detection обязателен; template-injection security тест-матрица обязательна; pipeline gap события обязательны; source_stale обязателен.

## Границы
Pipeline Core (rules/enrich/fingerprint/correlation) без UI.

## Зависимости
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Статус перепроверки
- Этап подтверждён проверками runtime+docs+CI gate.

## Шаги (строго линейно)

- [x] **1. Сделать:** Гарантировать перенос correlation (run_id/trace_id/span_id) из RawEvent в Incident.
  - [x] Incident содержит correlation поля:
    - [x] `run_id`
    - [x] `trace_id`
    - [x] `span_id`
  - [x] Правило переноса фиксировано: если поле отсутствует в RawEvent — в Incident пишется `null` (одно фиксированное решение)
  - [x] Correlation переносится без изменения значений (identity)
  - [x] **Проверка (pass/fail):** integration test `ingest→pipeline→incident` проверяет, что incident, сформированный из события с correlation, содержит те же значения; для события без correlation поля равны `null`.

- [x] **2. Сделать:** Реализовать collision detection → `data_quality.fingerprint_collision_suspected`.
  - [x] Fingerprint алгоритм фиксирован и описан (ссылка на doc, шаг 7)
  - [x] Collision критерий фиксирован:
    - [x] одинаковый fingerprint у двух событий, где canonical_json (без ts) различается
  - [x] При срабатывании collision генерируется событие `data_quality.fingerprint_collision_suspected` и оно попадает в snapshot/stream
  - [x] Событие содержит evidence_min:
    - [x] fingerprint
    - [x] count (>=2)
    - [x] sample_dedup_keys (минимум 2 значения)
    - [x] trace_id (если есть)
  - [x] **Проверка (pass/fail):** существует unit/integration тест “коллизия”, который принудительно создаёт два различных события с одинаковым fingerprint и проверяет генерацию `data_quality.fingerprint_collision_suspected`.

- [x] **3. Сделать:** Реализовать template injection security тест-матрицу (shell/template) для enrich/rules.
  - [x] Тест-матрица фиксирована и перечислена (в docs, шаг 6)
  - [x] Обязательные кейсы инъекций:
    - [x] `$(command)` (shell substitution)
    - [x] `` `command` `` (backticks)
    - [x] `${VAR}` (env expansion)
    - [x] `; rm -rf /` (command chaining)
    - [x] `| curl ...` (pipe)
    - [x] `../../` (path traversal)
  - [x] Политика обработки фиксирована: любые такие payload должны приводить к безопасной нейтрализации (escape) и не исполняться (одно фиксированное решение: “escape-only”)
  - [x] При срабатывании защиты генерируется `security.template_injection_blocked` (snapshot/stream) с evidence_min
  - [x] **Проверка (pass/fail):** security test suite зелёный; каждый кейс из матрицы подтверждает:
    - [x] отсутствие выполнения команд
    - [x] наличие безопасного результата (escaped)
    - [x] генерацию `security.template_injection_blocked`.

- [x] **4. Сделать:** Реализовать gap событие при падении стадии pipeline: `observability_gap.pipeline_stage_failed`.
  - [x] Любой unhandled exception в стадии pipeline приводит к:
    - [x] событию `observability_gap.pipeline_stage_failed` (snapshot/stream)
    - [x] сохранению evidence_min
  - [x] `observability_gap.pipeline_stage_failed` содержит `what/where/why/evidence/actions` и `trace_id`
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/pipeline_stage_failed.md`
  - [x] **Проверка (pass/fail):** induced failure test принудительно ломает одну стадию pipeline и проверяет:
    - [x] появление `observability_gap.pipeline_stage_failed` в snapshot/stream
    - [x] наличие `action_ref` и evidence_min.

- [x] **5. Сделать:** Реализовать source_stale → `observability_gap.source_stale`.
  - [x] Критерий stale фиксирован: `now_ms - source_last_seen_ms > 600000` (10 минут)
  - [x] Событие `observability_gap.source_stale` попадает в snapshot/stream и содержит evidence_min:
    - [x] source_id
    - [x] age_ms
    - [x] threshold_ms=600000
    - [x] trace_id (если есть)
  - [x] Событие зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/source_stale.md`
  - [x] **Проверка (pass/fail):** time-sim integration test симулирует отсутствие событий от source_id >10 минут и проверяет генерацию `observability_gap.source_stale`.

- [x] **6. Сделать:** RU-дока: rules/enrich + security матрица (источник правды для тестов шага 3).
  - [x] `docs/core/rules.md` существует и описывает формат rules (вход/выход/поля)
  - [x] `docs/core/enrich.md` существует и описывает enrich этапы (что добавляется/как)
  - [x] `docs/core/enrich.md` содержит раздел `template injection matrix` с перечислением кейсов из шага 3
  - [x] `docs/core/enrich.md` содержит правило “escape-only” (фиксированное решение)
  - [x] **Проверка (pass/fail):** документы существуют и содержат ключевые разделы.

- [x] **7. Сделать:** RU-дока: fingerprint алгоритм и collision semantics.
  - [x] `docs/core/fingerprint.md` существует
  - [x] содержит описание canonical_json (с отсортированными ключами; исключения полей перечислены)
  - [x] содержит описание hashing (sha256) и выходного формата fingerprint
  - [x] содержит раздел `collision detection` и критерий из шага 2
  - [x] **Проверка (pass/fail):** документ существует и содержит все пункты.

- [x] **8. Сделать:** RU-дока: pipeline overview и source stale.
  - [x] `docs/core/pipeline_overview.md` существует и описывает стадии pipeline по порядку
  - [x] `docs/core/source_stale.md` существует и фиксирует threshold 10 минут и поведение события
  - [x] **Проверка (pass/fail):** документы существуют и содержат перечисленные требования.

## Документация (RU)
- [x] docs/core/pipeline_overview.md
- [x] docs/core/rules.md
- [x] docs/core/enrich.md
- [x] docs/core/fingerprint.md
- [x] docs/core/source_stale.md
- [x] docs/runbooks/pipeline_stage_failed.md
- [x] docs/runbooks/source_stale.md

## Тестирование
- [x] unit: rules/enrich (валидные кейсы)
- [x] integration: ingest→pipeline→incident (correlation перенос, шаг 1)
- [x] integration: collision detection (шаг 2)
- [x] security: template injection matrix (шаг 3)
- [x] integration: induced failure → `observability_gap.pipeline_stage_failed` (шаг 4)
- [x] integration: time-sim source stale (шаг 5)

## CI gate
- [x] CI job `pipeline-tests` существует и зелёный (unit+integration шага 1/2/4/5)
- [x] CI job `pipeline-security-tests` существует и зелёный (шаг 3)
- [x] CI job `stage13-docs-gate` существует и запускает `scripts/ci/check_pipeline_stage13_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/core/enrich.md` содержит `template injection matrix` и `escape-only`
    - [x] `docs/core/fingerprint.md` содержит `sha256` и `canonical_json` и `collision`
    - [x] `docs/core/source_stale.md` содержит `600000` и `observability_gap.source_stale`
    - [x] runbooks содержат `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Correlation переносится из RawEvent в Incident и проверен интеграционным тестом.
- [x] Collision detection работает и проверен тестом; `data_quality.fingerprint_collision_suspected` видим в snapshot/stream.
- [x] Template injection защита реализована и проверена security suite; `security.template_injection_blocked` видим в snapshot/stream.
- [x] `observability_gap.pipeline_stage_failed` и `observability_gap.source_stale` реализованы, зарегистрированы и имеют runbook.
- [x] CI gate Stage 13 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
