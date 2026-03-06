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

- [ ] **1. Сделать:** Создать fixtures полного набора событий REGART (включая `ui.graph.empty` и `upstream_error`) и использовать их в тестах.
  - [ ] существует каталог fixtures: `packs/regart/fixtures/`
  - [ ] fixtures включают минимальный полный набор (каждый — отдельный файл):
    - [ ] `ui_proxy_unavailable.json` (или эквивалент)
    - [ ] `upstream_error.json`
    - [ ] `ui.graph.empty.json`
    - [ ] `network_error.json`
    - [ ] `tools_event.json`
    - [ ] `models_event.json`
    - [ ] `graph_event.json`
  - [ ] каждый fixture содержит обязательные поля correlation:
    - [ ] `run_id`
    - [ ] `trace_id`
    - [ ] `span_id`
  - [ ] каждый fixture содержит `source_id` и `source_seq` (для реалистичности pipeline)
  - [ ] **Проверка (pass/fail):** тесты pack реально читают fixtures из `packs/regart/fixtures/` и падают при удалении любого fixture файла.

- [ ] **2. Сделать:** Реализовать rules/enrich pack так, чтобы Incident сохранял correlation (`run_id/trace_id/span_id`) без изменения значений.
  - [ ] в pack есть rules/enrich, которые:
    - [ ] не перезаписывают `run_id/trace_id/span_id`, если они присутствуют
    - [ ] при отсутствии correlation поле в Incident становится `null` (одно фиксированное решение)
  - [ ] **Проверка (pass/fail):** pack tests сравнивают значения correlation в RawEvent fixture и в сформированном Incident (identity match) для всех fixtures шага 1.

- [ ] **3. Сделать:** Добавить фиксированные examples конфигов receivers для REGART (без двусмысленностей).
  - [ ] существует файл `packs/regart/examples/receivers.toml`
  - [ ] файл содержит примеры для ровно следующих receivers (каждый с уникальным `source_id` шаблоном):
    - [ ] `journald` (UNIT=ui-proxy.service)
    - [ ] `file_tail` (абсолютный путь: `/var/log/regart/ui-proxy.log`)
    - [ ] `stdout_stderr` (command_id: `regart-ui-proxy`)
    - [ ] `net_probe` (endpoint: `http://127.0.0.1:8090/health`)
  - [ ] **Проверка (pass/fail):** `receivers.toml` валиден (парсится), и pack test `pack_regart_examples_validate` проверяет наличие всех четырёх секций.

- [ ] **4. Сделать:** Реализовать gap при несовместимости pack с Core: `observability_gap.pack_incompatible`.
  - [ ] pack manifest фиксирует `core_version_range` (строка semver range)
  - [ ] при несовместимости (core_version не удовлетворяет range):
    - [ ] install fail (pack не активирован)
    - [ ] генерируется `observability_gap.pack_incompatible` (snapshot/stream)
  - [ ] `observability_gap.pack_incompatible` содержит evidence_min:
    - [ ] pack_name
    - [ ] pack_version
    - [ ] core_version
    - [ ] core_version_range
    - [ ] trace_id
  - [ ] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/pack_incompatible.md`
  - [ ] **Проверка (pass/fail):** induced test поднимает Core с версией вне диапазона и проверяет:
    - [ ] install fail
    - [ ] событие `observability_gap.pack_incompatible` видно в snapshot/stream.

## Документация (RU)
- [ ] docs/packs/regart/README.md
- [ ] docs/packs/regart/receivers_examples.md
- [ ] docs/packs/regart/troubleshooting.md
- [ ] docs/runbooks/pack_incompatible.md

## Тестирование
- [ ] unit/integration: fixtures → pipeline → incident (покрывает шаги 1–2)
- [ ] unit: validate examples `receivers.toml` (шаг 3)
- [ ] induced: incompatible pack install → `observability_gap.pack_incompatible` (шаг 4)
- [ ] runtime API: `scripts/tests/pack_regart_runtime_api.sh` проверяет ingest fixtures из `packs/regart/fixtures` и сохранение correlation в `/api/v1/incidents`

## CI gate
- [ ] CI job `pack-regart-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `pack-regart-runtime-api` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage20-docs-gate` существует и запускается на PR в main
- [ ] `stage20-docs-gate` запускает `scripts/ci/check_pack_regart_stage20_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет наличие runtime harness `scripts/tests/pack_regart_runtime_api.sh`
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/packs/regart/README.md` содержит `fixtures` и `correlation`
    - [ ] `docs/packs/regart/receivers_examples.md` содержит `journald` и `file_tail` и `stdout_stderr` и `net_probe`
    - [ ] `docs/packs/regart/troubleshooting.md` содержит `ui.graph.empty` и `upstream_error`
    - [ ] `docs/runbooks/pack_incompatible.md` содержит `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Fixtures полного набора REGART событий существуют и реально используются тестами.
- [ ] Correlation (`run_id/trace_id/span_id`) сохраняется в Incident по всем fixtures и подтверждена тестами.
- [ ] Examples receivers (4 секции) существуют и валидируются тестом.
- [ ] `observability_gap.pack_incompatible` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [ ] CI gate Stage 20 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
