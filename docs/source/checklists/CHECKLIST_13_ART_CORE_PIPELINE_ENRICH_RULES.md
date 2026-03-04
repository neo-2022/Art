A) Полный запрет опциональности:
# CHECKLIST 13 — Art Core Pipeline v1 (rules/enrich/correlation)
Файл: CHECKLIST_13_ART_CORE_PIPELINE_ENRICH_RULES.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение rules/enrich; изменение Incident схемы; изменение correlation модели; изменение политики security тестов шаблонов

## Цель
Pipeline однозначен и проверяем: correlation переносится в Incident; collision detection обязателен; template-injection security тест-матрица обязательна; pipeline gap события обязательны; source_stale обязателен.

## Границы
Pipeline Core (rules/enrich/fingerprint/correlation) без UI.

## Зависимости
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry

## Шаги (строго линейно)

- [ ] **1. Сделать:** Гарантировать перенос correlation (run_id/trace_id/span_id) из RawEvent в Incident.
  - [ ] Incident содержит correlation поля:
    - [ ] `run_id`
    - [ ] `trace_id`
    - [ ] `span_id`
  - [ ] Правило переноса фиксировано: если поле отсутствует в RawEvent — в Incident пишется `null` (одно фиксированное решение)
  - [ ] Correlation переносится без изменения значений (identity)
  - [ ] **Проверка (pass/fail):** integration test `ingest→pipeline→incident` проверяет, что incident, сформированный из события с correlation, содержит те же значения; для события без correlation поля равны `null`.

- [ ] **2. Сделать:** Реализовать collision detection → `data_quality.fingerprint_collision_suspected`.
  - [ ] Fingerprint алгоритм фиксирован и описан (ссылка на doc, шаг 7)
  - [ ] Collision критерий фиксирован:
    - [ ] одинаковый fingerprint у двух событий, где canonical_json (без ts) различается
  - [ ] При срабатывании collision генерируется событие `data_quality.fingerprint_collision_suspected` и оно попадает в snapshot/stream
  - [ ] Событие содержит evidence_min:
    - [ ] fingerprint
    - [ ] count (>=2)
    - [ ] sample_dedup_keys (минимум 2 значения)
    - [ ] trace_id (если есть)
  - [ ] **Проверка (pass/fail):** существует unit/integration тест “коллизия”, который принудительно создаёт два различных события с одинаковым fingerprint и проверяет генерацию `data_quality.fingerprint_collision_suspected`.

- [ ] **3. Сделать:** Реализовать template injection security тест-матрицу (shell/template) для enrich/rules.
  - [ ] Тест-матрица фиксирована и перечислена (в docs, шаг 6)
  - [ ] Обязательные кейсы инъекций:
    - [ ] `$(command)` (shell substitution)
    - [ ] `` `command` `` (backticks)
    - [ ] `${VAR}` (env expansion)
    - [ ] `; rm -rf /` (command chaining)
    - [ ] `| curl ...` (pipe)
    - [ ] `../../` (path traversal)
  - [ ] Политика обработки фиксирована: любые такие payload должны приводить к безопасной нейтрализации (escape) и не исполняться (одно фиксированное решение: “escape-only”)
  - [ ] При срабатывании защиты генерируется `security.template_injection_blocked` (snapshot/stream) с evidence_min
  - [ ] **Проверка (pass/fail):** security test suite зелёный; каждый кейс из матрицы подтверждает:
    - [ ] отсутствие выполнения команд
    - [ ] наличие безопасного результата (escaped)
    - [ ] генерацию `security.template_injection_blocked`.

- [ ] **4. Сделать:** Реализовать gap событие при падении стадии pipeline: `observability_gap.pipeline_stage_failed`.
  - [ ] Любой unhandled exception в стадии pipeline приводит к:
    - [ ] событию `observability_gap.pipeline_stage_failed` (snapshot/stream)
    - [ ] сохранению evidence_min
  - [ ] `observability_gap.pipeline_stage_failed` содержит `what/where/why/evidence/actions` и `trace_id`
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/pipeline_stage_failed.md`
  - [ ] **Проверка (pass/fail):** induced failure test принудительно ломает одну стадию pipeline и проверяет:
    - [ ] появление `observability_gap.pipeline_stage_failed` в snapshot/stream
    - [ ] наличие `action_ref` и evidence_min.

- [ ] **5. Сделать:** Реализовать source_stale → `observability_gap.source_stale`.
  - [ ] Критерий stale фиксирован: `now_ms - source_last_seen_ms > 600000` (10 минут)
  - [ ] Событие `observability_gap.source_stale` попадает в snapshot/stream и содержит evidence_min:
    - [ ] source_id
    - [ ] age_ms
    - [ ] threshold_ms=600000
    - [ ] trace_id (если есть)
  - [ ] Событие зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/source_stale.md`
  - [ ] **Проверка (pass/fail):** time-sim integration test симулирует отсутствие событий от source_id >10 минут и проверяет генерацию `observability_gap.source_stale`.

- [ ] **6. Сделать:** RU-дока: rules/enrich + security матрица (источник правды для тестов шага 3).
  - [ ] `docs/core/rules.md` существует и описывает формат rules (вход/выход/поля)
  - [ ] `docs/core/enrich.md` существует и описывает enrich этапы (что добавляется/как)
  - [ ] `docs/core/enrich.md` содержит раздел `template injection matrix` с перечислением кейсов из шага 3
  - [ ] `docs/core/enrich.md` содержит правило “escape-only” (фиксированное решение)
  - [ ] **Проверка (pass/fail):** документы существуют и содержат ключевые разделы.

- [ ] **7. Сделать:** RU-дока: fingerprint алгоритм и collision semantics.
  - [ ] `docs/core/fingerprint.md` существует
  - [ ] содержит описание canonical_json (с отсортированными ключами; исключения полей перечислены)
  - [ ] содержит описание hashing (sha256) и выходного формата fingerprint
  - [ ] содержит раздел `collision detection` и критерий из шага 2
  - [ ] **Проверка (pass/fail):** документ существует и содержит все пункты.

- [ ] **8. Сделать:** RU-дока: pipeline overview и source stale.
  - [ ] `docs/core/pipeline_overview.md` существует и описывает стадии pipeline по порядку
  - [ ] `docs/core/source_stale.md` существует и фиксирует threshold 10 минут и поведение события
  - [ ] **Проверка (pass/fail):** документы существуют и содержат перечисленные требования.

## Документация (RU)
- [ ] docs/core/pipeline_overview.md
- [ ] docs/core/rules.md
- [ ] docs/core/enrich.md
- [ ] docs/core/fingerprint.md
- [ ] docs/core/source_stale.md
- [ ] docs/runbooks/pipeline_stage_failed.md
- [ ] docs/runbooks/source_stale.md

## Тестирование
- [ ] unit: rules/enrich (валидные кейсы)
- [ ] integration: ingest→pipeline→incident (correlation перенос, шаг 1)
- [ ] integration: collision detection (шаг 2)
- [ ] security: template injection matrix (шаг 3)
- [ ] integration: induced failure → `observability_gap.pipeline_stage_failed` (шаг 4)
- [ ] integration: time-sim source stale (шаг 5)

## CI gate
- [ ] CI job `pipeline-tests` существует и зелёный (unit+integration шага 1/2/4/5)
- [ ] CI job `pipeline-security-tests` существует и зелёный (шаг 3)
- [ ] CI job `stage13-docs-gate` существует и запускает `scripts/ci/check_pipeline_stage13_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/core/enrich.md` содержит `template injection matrix` и `escape-only`
    - [ ] `docs/core/fingerprint.md` содержит `sha256` и `canonical_json` и `collision`
    - [ ] `docs/core/source_stale.md` содержит `600000` и `observability_gap.source_stale`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Correlation переносится из RawEvent в Incident и проверен интеграционным тестом.
- [ ] Collision detection работает и проверен тестом; `data_quality.fingerprint_collision_suspected` видим в snapshot/stream.
- [ ] Template injection защита реализована и проверена security suite; `security.template_injection_blocked` видим в snapshot/stream.
- [ ] `observability_gap.pipeline_stage_failed` и `observability_gap.source_stale` реализованы, зарегистрированы и имеют runbook.
- [ ] CI gate Stage 13 зелёный.

