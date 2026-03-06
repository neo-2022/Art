# CHECKLIST 45 — Forensic Enrichment + Graph Exploration
Файл: CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение Linux forensic policy, graph exploration model, advanced evidence enrichment
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Довести forensic и relationship exploration differentiators до production-grade уровня.

## Границы
- Включено: eBPF evidence linking, graph-backed DNA exploration, advanced relationship navigation.
- Исключено: Linux-unsafe data capture и неконтролируемое расширение forensic surface.

## Зависимости
- CHECKLIST 44 
- CHECKLIST 37 
- CHECKLIST 35 

## Шаги (строго линейно)
- [ ] 1. Сделать: внедрить eBPF evidence linking policy и безопасный capture pipeline для Linux.
  - [ ] Проверка (pass/fail): capture pipeline привязывает системные следы к evidence без нарушения privacy/policy ограничений.
  - [ ] Артефакт результата: pipeline spec + security review log.
- [ ] 2. Сделать: внедрить graph-backed DNA exploration в UI и local derived stores.
  - [ ] Проверка (pass/fail): graph exploration позволяет объяснимо навигировать `dna -> evidence -> incident -> action -> audit`.
  - [ ] Артефакт результата: graph exploration report + UI artifact.
- [ ] 3. Сделать: связать graph exploration с Flow/Spatial surfaces без разрыва inspectability.
  - [ ] Проверка (pass/fail): graph/flow selection sync и evidence lineage stay deterministic.
  - [ ] Артефакт результата: sync integration log.
- [ ] 4. Сделать: зафиксировать future-safe cryptographic extension path для evidence signing.
  - [ ] Проверка (pass/fail): architecture doc фиксирует upgrade path для stronger/post-quantum signing without current runtime ambiguity.
  - [ ] Артефакт результата: crypto extension note.
- [ ] 5. Сделать: зарегистрировать observability-gap для деградации forensic enrichment контура.
  - [ ] Событие: `observability_gap.forensic_enrichment_degraded`.
  - [ ] evidence_min: `capture_mode`, `graph_scope`, `policy_block`, `trace_id`, `kernel_profile`.
  - [ ] action_ref: `docs/runbooks/forensic_enrichment_degraded.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md
- [ ] docs/source/spatial_store_v0_2.md
- [ ] docs/ops/platform-support.md
- [ ] docs/runbooks/forensic_enrichment_degraded.md

## Тестирование
- [ ] unit: graph derivation primitives.
- [ ] integration: evidence linking pipeline.
- [ ] e2e: graph exploration and flow sync.
- [ ] security: privacy/policy enforcement on forensic capture.
- [ ] perf: graph exploration budget.
- [ ] chaos: capture unavailable -> graceful degraded mode.

## CI gate
- [ ] `stage45-forensic-graph-gate`

## DoD
- [ ] eBPF enrichment и graph-backed exploration стали controlled product capability.
- [ ] privacy/policy ограничения сохраняются.
- [ ] observability-gap событие этапа 45 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: финальный production GO возможен только после честной оценки обязательности этапа 45 в целевом релизном профиле.
- Артефакты закрытия: pipeline specs + graph artifacts + security review logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
