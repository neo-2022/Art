# CHECKLIST 34 — Perf / Load / Coverage Ratchet
Файл: CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение perf budgets, load profile, coverage policy, DNA throughput targets
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

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
- [x] 1. Сделать: зафиксировать перф-бюджеты DNA Core.
  - [x] Проверка (pass/fail): `docs/source/perf_load_coverage_v0_2.md` содержит измеримые бюджеты p95/p99/throughput.
  - [x] Артефакт результата: версия документа с числами и test profile IDs.
- [x] 2. Сделать: load suite ingest v2 + dna clustering для профилей steady/burst/skewed.
  - [x] Проверка (pass/fail): есть прогоны `10k/сек` и `100k/сек`, p95 в пределах budget.
  - [x] Артефакт результата: load report с таблицей метрик.
- [x] 3. Сделать: profile CPU/memory hot paths (perf/flamegraph compatible outputs).
  - [x] Проверка (pass/fail): отчёт содержит top CPU/heap hotspots и remediation actions.
  - [x] Артефакт результата: profiling report.
- [x] 4. Сделать: overload tests на 2x и 3x budget с контролируемой деградацией.
  - [x] Проверка (pass/fail): latency деградирует предсказуемо и без отказа data path.
  - [x] Артефакт результата: overload report.
- [x] 5. Сделать: soak tests backlog/recovery с zero-loss инвариантом.
  - [x] Проверка (pass/fail): zero-loss assertion PASS.
  - [x] Артефакт результата: soak report.
- [x] 6. Сделать: perf regression gate для snapshot/stream/local index.
  - [x] Проверка (pass/fail): regression suite PASS.
  - [x] Артефакт результата: perf regression report.
- [x] 7. Сделать: ratchet policy ключевых метрик производительности.
  - [x] Проверка (pass/fail): ухудшение метрик > `5%` блокируется CI.
  - [x] Артефакт результата: gate logs + ratchet snapshot.
- [x] 8. Сделать: зафиксировать budgets local-stores и offload heavy paths в workers.
  - [x] Проверка (pass/fail): `find similar by DNA p95` и index-update latency в пределах budget, main thread не блокируется.
  - [x] Артефакт результата: local-stores perf report.
- [x] 9. Сделать: coverage ratchet gate и baseline policy.
  - [x] Проверка (pass/fail): `bash scripts/ci/check_coverage_ratchet_v0_2.sh` PASS.
  - [x] Артефакт результата: baseline file + gate logs.
- [x] 10. Сделать: observability-gap контроль perf/coverage/determinism regressions.
  - [x] События:
    - `observability_gap.perf_budget_exceeded`
    - `observability_gap.coverage_ratchet_failed`
    - `observability_gap.dna_determinism_violation`
    - `observability_gap.local_store_latency_exceeded`
    - `observability_gap.innovation_experiment_regression`
  - [x] evidence_min:
    - `perf_budget_exceeded`: `suite`, `metric`, `actual`, `budget`, `trace_id`.
    - `coverage_ratchet_failed`: `module`, `metric`, `baseline`, `actual`, `trace_id`.
    - `dna_determinism_violation`: `build_id`, `dna_id`, `canonical_hash`, `payload_hash`, `replay_window`, `trace_id`.
    - `local_store_latency_exceeded`: `store_type`, `operation`, `p95_ms`, `budget_ms`, `trace_id`.
    - `innovation_experiment_regression`: `experiment`, `metric`, `baseline`, `actual`, `threshold`, `trace_id`.
  - [x] action_ref:
    - `docs/runbooks/perf_budget_exceeded.md`
    - `docs/runbooks/coverage_ratchet_failed.md`
    - `docs/runbooks/dna_determinism_violation.md`
    - `docs/runbooks/local_store_latency_exceeded.md`
    - `docs/runbooks/innovation_experiment_regression.md`
  - [x] Проверка (pass/fail): registry записи + runbook файлы.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 11. Сделать: зафиксировать memory budgets local-stores и heap growth policy.
  - [x] Проверка (pass/fail): perf doc содержит p95 memory budgets для cache/index/analytics/spatial adapters.
  - [x] Артефакт результата: memory budget section + profiling log.
- [x] 12. Сделать: добавить replay-determinism regression suite в регулярный perf контур.
  - [x] Проверка (pass/fail): replay determinism suite PASS и включает сравнение с предыдущим baseline.
  - [x] Артефакт результата: replay regression report.
- [x] 13. Сделать: зафиксировать экспериментальные KPI для RTP/LRC/NRAC и добавить regression gate.
  - [x] Проверка (pass/fail): отчёт содержит baseline/actual по метрикам false-positive, runbook-mismatch, rollback-rate и не допускает ухудшения за пределами policy.
  - [x] Артефакт результата: innovation KPI report + gate log.
- [x] 14. Сделать: зафиксировать flow-mode 2D baseline budget и watchdog-политику деградации.
  - [x] Budget: `1000 nodes pan/zoom p95 <= 50 ms`.
  - [x] Проверка (pass/fail): perf suite подтверждает budget и auto-downgrade profile при превышении.
  - [x] Артефакт результата: flow perf report + watchdog activation log.

## Документация (RU)
- [x] docs/source/perf_load_coverage_v0_2.md
- [x] docs/source/coverage_ratchet_baseline_v0_2.json
- [x] docs/source/dna_core_determinism_performance_assurance.md
- [x] docs/runbooks/perf_budget_exceeded.md
- [x] docs/runbooks/coverage_ratchet_failed.md
- [x] docs/runbooks/dna_determinism_violation.md
- [x] docs/runbooks/local_store_latency_exceeded.md
- [x] docs/source/risk_register_v0_2.md
- [x] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [x] Tier4 load: ingest/snapshot/stream/local index.
- [x] Tier4 load: DNA profiles steady/burst/skewed для 10k/сек и 100k/сек.
- [x] Tier4 load: local-stores профили cache/index/analytics/spatial adapters.
- [x] Tier4 perf: local-stores p95 memory budgets и heap growth.
- [x] soak: backlog/recovery zero-loss.
- [x] perf regression: p95/p99 budgets.
- [x] perf regression: replay determinism against baseline.
- [x] Tier4 experiment regression: RTP/LRC/NRAC KPI against baseline.
- [x] Tier4 perf: flow mode 2D (`1000 nodes`) p95 budget + watchdog fallback.
- [x] coverage: global non-decrease + module targets.
- [x] chaos: degradation under throttling/partial failures.

## CI gate
- [x] `stage34-perf-load-tests`
- [x] `coverage-ratchet-gate`
- [x] `stage35-flow-perf-2d-gate`

## DoD
- [x] Перф бюджеты документированы и соблюдаются.
- [x] Ratchet-политика блокирует ухудшение > 5%.
- [x] Coverage ratchet защищает от снижения метрик.
- [x] observability-gap события этапа 34 зарегистрированы и имеют runbook.
- [x] Риск R8 из risk register закрыт тестами и perf budget контролем.
- [x] Экспериментальные треки RTP/LRC/NRAC имеют измеримый KPI status и не деградируют базовые SLO.
- [x] Flow mode 2D baseline и watchdog деградации зафиксированы и проверяются CI-gate.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_35 запрещён до полного закрытия CHECKLIST_34.
- Артефакты закрытия: load/soak/perf reports + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
