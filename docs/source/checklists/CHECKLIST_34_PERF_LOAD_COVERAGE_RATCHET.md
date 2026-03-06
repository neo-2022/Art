# CHECKLIST 34 — Perf / Load / Coverage Ratchet
Файл: CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение perf budgets, load profile, coverage policy, DNA throughput targets

## Цель
Зафиксировать runtime бюджеты производительности DNA Core/Console и ratchet-политику, которая блокирует скрытые регрессии.

## Границы
- Включено: load/soak/perf gates для Core v2 и Console local index.
- Включено: coverage non-decrease + target policy.
- Исключено: synthetic benchmark без runtime верификации.

## Зависимости
- CHECKLIST 22 (E2E/load baseline)
- CHECKLIST 29
- CHECKLIST 30
- CHECKLIST 33 (безопасные действия)

## Шаги (строго линейно)
- [ ] 1. Сделать: зафиксировать перф-бюджеты DNA Core.
  - [ ] Проверка (pass/fail): `docs/source/perf_load_coverage_v0_2.md` содержит измеримые бюджеты p95/p99/throughput.
  - [ ] Артефакт результата: версия документа с числами и test profile IDs.
- [ ] 2. Сделать: load suite ingest v2 + dna clustering для профилей steady/burst/skewed.
  - [ ] Проверка (pass/fail): есть прогоны `10k/сек` и `100k/сек`, p95 в пределах budget.
  - [ ] Артефакт результата: load report с таблицей метрик.
- [ ] 3. Сделать: profile CPU/memory hot paths (perf/flamegraph compatible outputs).
  - [ ] Проверка (pass/fail): отчёт содержит top CPU/heap hotspots и remediation actions.
  - [ ] Артефакт результата: profiling report.
- [ ] 4. Сделать: overload tests на 2x и 3x budget с контролируемой деградацией.
  - [ ] Проверка (pass/fail): latency деградирует предсказуемо и без отказа data path.
  - [ ] Артефакт результата: overload report.
- [ ] 5. Сделать: soak tests backlog/recovery с zero-loss инвариантом.
  - [ ] Проверка (pass/fail): zero-loss assertion PASS.
  - [ ] Артефакт результата: soak report.
- [ ] 6. Сделать: perf regression gate для snapshot/stream/local index.
  - [ ] Проверка (pass/fail): regression suite PASS.
  - [ ] Артефакт результата: perf regression report.
- [ ] 7. Сделать: ratchet policy ключевых метрик производительности.
  - [ ] Проверка (pass/fail): ухудшение метрик > `5%` блокируется CI.
  - [ ] Артефакт результата: gate logs + ratchet snapshot.
- [ ] 8. Сделать: зафиксировать budgets local-stores и offload heavy paths в workers.
  - [ ] Проверка (pass/fail): `find similar by DNA p95` и index-update latency в пределах budget, main thread не блокируется.
  - [ ] Артефакт результата: local-stores perf report.
- [ ] 9. Сделать: coverage ratchet gate и baseline policy.
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_coverage_ratchet_v0_2.sh` PASS.
  - [ ] Артефакт результата: baseline file + gate logs.
- [ ] 10. Сделать: observability-gap контроль perf/coverage/determinism regressions.
  - [ ] События:
    - `observability_gap.perf_budget_exceeded`
    - `observability_gap.coverage_ratchet_failed`
    - `observability_gap.dna_determinism_violation`
    - `observability_gap.local_store_latency_exceeded`
    - `observability_gap.innovation_experiment_regression`
  - [ ] evidence_min:
    - `perf_budget_exceeded`: `suite`, `metric`, `actual`, `budget`, `trace_id`.
    - `coverage_ratchet_failed`: `module`, `metric`, `baseline`, `actual`, `trace_id`.
    - `dna_determinism_violation`: `build_id`, `dna_id`, `canonical_hash`, `payload_hash`, `replay_window`, `trace_id`.
    - `local_store_latency_exceeded`: `store_type`, `operation`, `p95_ms`, `budget_ms`, `trace_id`.
    - `innovation_experiment_regression`: `experiment`, `metric`, `baseline`, `actual`, `threshold`, `trace_id`.
  - [ ] action_ref:
    - `docs/runbooks/perf_budget_exceeded.md`
    - `docs/runbooks/coverage_ratchet_failed.md`
    - `docs/runbooks/dna_determinism_violation.md`
    - `docs/runbooks/local_store_latency_exceeded.md`
    - `docs/runbooks/innovation_experiment_regression.md`
  - [ ] Проверка (pass/fail): registry записи + runbook файлы.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 11. Сделать: зафиксировать memory budgets local-stores и heap growth policy.
  - [ ] Проверка (pass/fail): perf doc содержит p95 memory budgets для cache/index/analytics/spatial adapters.
  - [ ] Артефакт результата: memory budget section + profiling log.
- [ ] 12. Сделать: добавить replay-determinism regression suite в регулярный perf контур.
  - [ ] Проверка (pass/fail): replay determinism suite PASS и включает сравнение с предыдущим baseline.
  - [ ] Артефакт результата: replay regression report.
- [ ] 13. Сделать: зафиксировать экспериментальные KPI для RTP/LRC/NRAC и добавить regression gate.
  - [ ] Проверка (pass/fail): отчёт содержит baseline/actual по метрикам false-positive, runbook-mismatch, rollback-rate и не допускает ухудшения за пределами policy.
  - [ ] Артефакт результата: innovation KPI report + gate log.

## Документация (RU)
- [ ] docs/source/perf_load_coverage_v0_2.md
- [ ] docs/source/coverage_ratchet_baseline_v0_2.json
- [ ] docs/source/dna_core_determinism_performance_assurance.md
- [ ] docs/runbooks/perf_budget_exceeded.md
- [ ] docs/runbooks/coverage_ratchet_failed.md
- [ ] docs/runbooks/dna_determinism_violation.md
- [ ] docs/runbooks/local_store_latency_exceeded.md
- [ ] docs/source/risk_register_v0_2.md
- [ ] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [ ] Tier4 load: ingest/snapshot/stream/local index.
- [ ] Tier4 load: DNA profiles steady/burst/skewed для 10k/сек и 100k/сек.
- [ ] Tier4 load: local-stores профили cache/index/analytics/spatial adapters.
- [ ] Tier4 perf: local-stores p95 memory budgets и heap growth.
- [ ] soak: backlog/recovery zero-loss.
- [ ] perf regression: p95/p99 budgets.
- [ ] perf regression: replay determinism against baseline.
- [ ] Tier4 experiment regression: RTP/LRC/NRAC KPI against baseline.
- [ ] coverage: global non-decrease + module targets.
- [ ] chaos: degradation under throttling/partial failures.

## CI gate
- [ ] `stage34-perf-load-tests`
- [ ] `coverage-ratchet-gate`

## DoD
- [ ] Перф бюджеты документированы и соблюдаются.
- [ ] Ratchet-политика блокирует ухудшение > 5%.
- [ ] Coverage ratchet защищает от снижения метрик.
- [ ] observability-gap события этапа 34 зарегистрированы и имеют runbook.
- [ ] Риск R8 из risk register закрыт тестами и perf budget контролем.
- [ ] Экспериментальные треки RTP/LRC/NRAC имеют измеримый KPI status и не деградируют базовые SLO.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_35 запрещён до полного закрытия CHECKLIST_34.
- Артефакты закрытия: load/soak/perf reports + registry/runbook diff.
