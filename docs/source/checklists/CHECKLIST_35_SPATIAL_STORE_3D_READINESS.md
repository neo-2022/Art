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
- [ ] 1. Сделать: Spatial Store API contract (`runtime SoA`, `persist binary chunks`).
  - [ ] Проверка (pass/fail): spatial contract unit tests PASS.
  - [ ] Артефакт результата: API spec + unit test log.
- [ ] 2. Сделать: spatial index для picking/visibility (octree/BVH contract).
  - [ ] Проверка (pass/fail): picking complexity tests PASS (без полного скана всех узлов).
  - [ ] Артефакт результата: complexity report.
- [ ] 3. Сделать: deterministic layout и 2D<->3D selection sync.
  - [ ] Проверка (pass/fail): integration sync tests PASS.
  - [ ] Артефакт результата: integration logs.
- [ ] 4. Сделать: observability-gap контроль деградации spatial index.
  - [ ] Событие: `observability_gap.spatial_index_degraded`.
  - [ ] evidence_min: `layout_id`, `node_count`, `picking_ms`, `threshold_ms`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/spatial_index_degraded.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 5. Сделать: оформить MVP scope 3D readiness и запрет на расширение scope до PASS базовых критериев.
  - [ ] Проверка (pass/fail): `docs/source/spatial_store_v0_2.md` содержит раздел `3D MVP Scope` с фиксированным перечнем функций.
  - [ ] Артефакт результата: spatial doc diff.
- [ ] 6. Сделать: ранний прототип визуализации и тесты на слабых GPU.
  - [ ] Проверка (pass/fail): perf-тесты содержат профиль `weak-gpu` (Intel UHD 620 класс), критерий авто-деградации качества (LOD + упрощённая графика) и budget `p95 < 50ms` для picking/scene update.
  - [ ] Артефакт результата: прототип отчёт + weak-gpu perf log.
- [ ] 7. Сделать: добавить GPU capability profiling и deterministic fallback policy.
  - [ ] Проверка (pass/fail): startup profiling определяет класс GPU и включает предсказуемый fallback profile.
  - [ ] Артефакт результата: profiling matrix + fallback policy report.
- [ ] 8. Сделать: внедрить Advanced Control guardrail для Visual Flow Mode.
  - [ ] Политика: advanced flow включается только feature-flag, при нарушении SLO/perf автоматически переводится в read-only mode.
  - [ ] Проверка (pass/fail): guardrail tests подтверждают auto-downgrade при превышении budget.
  - [ ] Артефакт результата: guardrail policy report + test log.
- [ ] 9. Сделать: закрыть inspectability/snapshot/replay/diff контур для semantic node types.
  - [ ] Проверка (pass/fail): по каждому типу `dna_cloud|incident_cloud|gap_cloud|service_node|store_node|buffer_node|agent_node` клик открывает Evidence Panel с lineage.
  - [ ] Проверка (pass/fail): snapshot state serialize/restore детерминирован без потери позиций/видимости.
  - [ ] Артефакт результата: flow inspectability report + snapshot replay report.

## Документация (RU)
- [ ] docs/source/spatial_store_v0_2.md
- [ ] docs/runbooks/spatial_index_degraded.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] unit: spatial primitives и storage adapters.
- [ ] integration: 2D<->3D selection sync.
- [ ] perf: picking/visibility/LOD budgets.
- [ ] chaos: corrupted chunk recovery.
- [ ] load: scene scale-up tests.
- [ ] perf: weak-gpu fallback tests.
- [ ] integration: GPU capability profiling и deterministic fallback activation.
- [ ] integration: advanced-flow guardrail (feature-flag + auto-downgrade).
- [ ] e2e: flow inspectability для всех semantic node types.
- [ ] e2e: freeze/snapshot/replay/diff state restore.
- [ ] soak: длительная работа spatial updates.

## CI gate
- [ ] `stage35-spatial-readiness-tests`
- [ ] `stage35-flow-inspectability-tests`
- [ ] `stage35-flow-snapshot-replay-tests`
- [ ] `stage35-flow-perf-2d-gate`

## DoD
- [ ] Spatial Store contract реализован и покрыт тестами.
- [ ] Picking/visibility проходит performance budgets.
- [ ] observability-gap событие этапа 35 зарегистрировано и имеет runbook.
- [ ] Риск R10 из risk register закрыт прототипом, MVP scope lock и weak-gpu тестами.
- [ ] Advanced Control guardrail предотвращает разрыв UX между ранними и поздними интерфейсными слоями.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_36 запрещён до полного закрытия CHECKLIST_35.
- Артефакты закрытия: tests + perf reports + registry/runbook diff.
