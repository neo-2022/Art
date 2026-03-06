A) Полный запрет опциональности:
# CHECKLIST 20 — Pack REGART
Файл: CHECKLIST_20_PACK_REGART.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение REGART событий; изменение correlation полей; изменение формата packs v1; изменение schema RawEvent/Incident
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Pack REGART полностью покрывает события REGART (UI Proxy/graph/tools/models/network/ui.graph.empty/upstream_error), сохраняет correlation, содержит фиксированные примеры конфигов receivers, и имеет детерминированные тесты совместимости/контрактов.

## Границы
Только Pack REGART: fixtures, rules/enrich, docs, тесты pack.  
Не включает изменения Core/Agent вне требований совместимости packs.

## Зависимости
- CHECKLIST 06 — REGART→Art Bridge readiness
- CHECKLIST 19 — Packs framework
- CHECKLIST 13 — Pipeline (correlation перенос в Incident)

## Шаги (строго линейно)

- [x] **1. Сделать:** Создать fixtures полного набора событий REGART (включая `ui.graph.empty` и `upstream_error`) и использовать их в тестах.
  - [x] существует каталог fixtures: `packs/regart/fixtures/`
  - [x] fixtures включают минимальный полный набор (каждый — отдельный файл):
    - [x] `ui_proxy_unavailable.json` (или эквивалент)
    - [x] `upstream_error.json`
    - [x] `ui.graph.empty.json`
    - [x] `network_error.json`
    - [x] `tools_event.json`
    - [x] `models_event.json`
    - [x] `graph_event.json`
  - [x] каждый fixture содержит обязательные поля correlation:
    - [x] `run_id`
    - [x] `trace_id`
    - [x] `span_id`
  - [x] каждый fixture содержит `source_id` и `source_seq` (для реалистичности pipeline)
  - [x] **Проверка (pass/fail):** тесты pack реально читают fixtures из `packs/regart/fixtures/` и падают при удалении любого fixture файла.

- [x] **2. Сделать:** Реализовать rules/enrich pack так, чтобы Incident сохранял correlation (`run_id/trace_id/span_id`) без изменения значений.
  - [x] в pack есть rules/enrich, которые:
    - [x] не перезаписывают `run_id/trace_id/span_id`, если они присутствуют
    - [x] при отсутствии correlation поле в Incident становится `null` (одно фиксированное решение)
  - [x] **Проверка (pass/fail):** pack tests сравнивают значения correlation в RawEvent fixture и в сформированном Incident (identity match) для всех fixtures шага 1.

- [x] **3. Сделать:** Добавить фиксированные examples конфигов receivers для REGART (без двусмысленностей).
  - [x] существует файл `packs/regart/examples/receivers.toml`
  - [x] файл содержит примеры для ровно следующих receivers (каждый с уникальным `source_id` шаблоном):
    - [x] `journald` (UNIT=ui-proxy.service)
    - [x] `file_tail` (абсолютный путь: `/var/log/regart/ui-proxy.log`)
    - [x] `stdout_stderr` (command_id: `regart-ui-proxy`)
    - [x] `net_probe` (endpoint: `http://127.0.0.1:8090/health`)
  - [x] **Проверка (pass/fail):** `receivers.toml` валиден (парсится), и pack test `pack_regart_examples_validate` проверяет наличие всех четырёх секций.

- [x] **4. Сделать:** Реализовать gap при несовместимости pack с Core: `observability_gap.pack_incompatible`.
  - [x] pack manifest фиксирует `core_version_range` (строка semver range)
  - [x] при несовместимости (core_version не удовлетворяет range):
    - [x] install fail (pack не активирован)
    - [x] генерируется `observability_gap.pack_incompatible` (snapshot/stream)
  - [x] `observability_gap.pack_incompatible` содержит evidence_min:
    - [x] pack_name
    - [x] pack_version
    - [x] core_version
    - [x] core_version_range
    - [x] trace_id
  - [x] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/pack_incompatible.md`
  - [x] **Проверка (pass/fail):** induced test поднимает Core с версией вне диапазона и проверяет:
    - [x] install fail
    - [x] событие `observability_gap.pack_incompatible` видно в snapshot/stream.

## Документация (RU)
- [x] docs/packs/regart/README.md
- [x] docs/packs/regart/receivers_examples.md
- [x] docs/packs/regart/troubleshooting.md
- [x] docs/runbooks/pack_incompatible.md

## Тестирование
- [x] unit/integration: fixtures → pipeline → incident (покрывает шаги 1–2)
- [x] unit: validate examples `receivers.toml` (шаг 3)
- [x] induced: incompatible pack install → `observability_gap.pack_incompatible` (шаг 4)
- [x] runtime API: `scripts/tests/pack_regart_runtime_api.sh` проверяет ingest fixtures из `packs/regart/fixtures` и сохранение correlation в `/api/v1/incidents`

## CI gate
- [x] CI job `pack-regart-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `pack-regart-runtime-api` существует и запускается на PR в main; job зелёный
- [x] CI job `stage20-docs-gate` существует и запускается на PR в main
- [x] `stage20-docs-gate` запускает `scripts/ci/check_pack_regart_stage20_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет наличие runtime harness `scripts/tests/pack_regart_runtime_api.sh`
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/packs/regart/README.md` содержит `fixtures` и `correlation`
    - [x] `docs/packs/regart/receivers_examples.md` содержит `journald` и `file_tail` и `stdout_stderr` и `net_probe`
    - [x] `docs/packs/regart/troubleshooting.md` содержит `ui.graph.empty` и `upstream_error`
    - [x] `docs/runbooks/pack_incompatible.md` содержит `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Fixtures полного набора REGART событий существуют и реально используются тестами.
- [x] Correlation (`run_id/trace_id/span_id`) сохраняется в Incident по всем fixtures и подтверждена тестами.
- [x] Examples receivers (4 секции) существуют и валидируются тестом.
- [x] `observability_gap.pack_incompatible` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [x] CI gate Stage 20 зелёный.
