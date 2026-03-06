# CHECKLIST 35 — Spatial Store + 3D Readiness
Файл: CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение spatial store contracts, picking algorithm, LOD policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Реализовать contract-ready Spatial Store для детерминированного 3D/XR рендера без brute-force перебора.

## Границы
- Включено: Spatial API, TypedArrays runtime, binary chunks persist, picking/visibility index.
- Исключено: production VR/AR UI.

## Зависимости
- CHECKLIST 28 (Console foundation закрыт)
- CHECKLIST 34 (perf/load budgets закрыты)
- CHECKLIST 30 (foundation evidence/ui-laws закрыт, для раннего spatial прототипа)

## Шаги (строго линейно)
- [x] 1. Сделать: Spatial Store API contract (`runtime SoA`, `persist binary chunks`).
  - [x] Проверка (pass/fail): spatial contract unit tests PASS.
  - [x] Артефакт результата: API spec + unit test log.
- [x] 2. Сделать: spatial index для picking/visibility (octree/BVH contract).
  - [x] Проверка (pass/fail): picking complexity tests PASS (без полного скана всех узлов).
  - [x] Артефакт результата: complexity report.
- [x] 3. Сделать: deterministic layout и 2D<->3D selection sync.
  - [x] Проверка (pass/fail): integration sync tests PASS.
  - [x] Артефакт результата: integration logs.
- [x] 4. Сделать: observability-gap контроль деградации spatial index.
  - [x] Событие: `observability_gap.spatial_index_degraded`.
  - [x] evidence_min: `layout_id`, `node_count`, `picking_ms`, `threshold_ms`, `trace_id`.
  - [x] action_ref: `docs/runbooks/spatial_index_degraded.md`.
  - [x] Проверка (pass/fail): registry запись + runbook файл.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 5. Сделать: оформить MVP scope 3D readiness и запрет на расширение scope до PASS базовых критериев.
  - [x] Проверка (pass/fail): `docs/source/spatial_store_v0_2.md` содержит раздел `3D MVP Scope` с фиксированным перечнем функций.
  - [x] Артефакт результата: spatial doc diff.
- [x] 6. Сделать: ранний прототип визуализации и тесты на слабых GPU.
  - [x] Проверка (pass/fail): perf-тесты содержат профиль `weak-gpu` (Intel UHD 620 класс), критерий авто-деградации качества (LOD + упрощённая графика) и budget `p95 < 50ms` для picking/scene update.
  - [x] Артефакт результата: прототип отчёт + weak-gpu perf log.
- [x] 7. Сделать: добавить GPU capability profiling и deterministic fallback policy.
  - [x] Проверка (pass/fail): startup profiling определяет класс GPU и включает предсказуемый fallback profile.
  - [x] Артефакт результата: profiling matrix + fallback policy report.
- [x] 8. Сделать: внедрить Advanced Control guardrail для Visual Flow Mode.
  - [x] Политика: advanced flow включается только feature-flag, при нарушении SLO/perf автоматически переводится в read-only mode.
  - [x] Проверка (pass/fail): guardrail tests подтверждают auto-downgrade при превышении budget.
  - [x] Артефакт результата: guardrail policy report + test log.
- [x] 9. Сделать: закрыть inspectability/snapshot/replay/diff контур для semantic node types.
  - [x] Проверка (pass/fail): по каждому типу `dna_cloud|incident_cloud|gap_cloud|service_node|store_node|buffer_node|agent_node` клик открывает Evidence Panel с lineage.
  - [x] Проверка (pass/fail): snapshot state serialize/restore детерминирован без потери позиций/видимости.
  - [x] Артефакт результата: flow inspectability report + snapshot replay report.

## Документация (RU)
- [x] docs/source/spatial_store_v0_2.md
- [x] docs/runbooks/spatial_index_degraded.md
- [x] docs/source/risk_register_v0_2.md

## Тестирование
- [x] unit: spatial primitives и storage adapters.
- [x] integration: 2D<->3D selection sync.
- [x] perf: picking/visibility/LOD budgets.
- [x] chaos: corrupted chunk recovery.
- [x] load: scene scale-up tests.
- [x] perf: weak-gpu fallback tests.
- [x] integration: GPU capability profiling и deterministic fallback activation.
- [x] integration: advanced-flow guardrail (feature-flag + auto-downgrade).
- [x] e2e: flow inspectability для всех semantic node types.
- [x] e2e: freeze/snapshot/replay/diff state restore.
- [x] soak: длительная работа spatial updates.

## CI gate
- [x] `stage35-spatial-readiness-tests`
- [x] `stage35-flow-inspectability-tests`
- [x] `stage35-flow-snapshot-replay-tests`
- [x] `stage35-flow-perf-2d-gate`

## DoD
- [x] Spatial Store contract реализован и покрыт тестами.
- [x] Picking/visibility проходит performance budgets.
- [x] observability-gap событие этапа 35 зарегистрировано и имеет runbook.
- [x] Риск R10 из risk register закрыт прототипом, MVP scope lock и weak-gpu тестами.
- [x] Advanced Control guardrail предотвращает разрыв UX между ранними и поздними интерфейсными слоями.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_36 запрещён до полного закрытия CHECKLIST_35.
- Артефакты закрытия: tests + perf reports + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
