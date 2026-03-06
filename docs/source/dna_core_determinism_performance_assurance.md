# DNA Core Determinism & Performance Assurance Program (v0.2)

Последняя актуализация: 2026-03-06
Статус: MANDATORY
Связанные этапы: CHECKLIST_29, CHECKLIST_34, CHECKLIST_37, CHECKLIST_38

## Назначение
Этот документ устраняет риск "самолёт без двигателя": Tier B Console запрещено считать production-ready, пока DNA Core не докажет детерминизм, устойчивость под нагрузкой и контролируемый rollout/rollback.

## Обязательные инварианты
1. Детерминизм: одинаковый набор событий (с учётом порядка и правил canonicalization) даёт одинаковые `dna_id` и одинаковые границы кластеров.
2. Версионирование: изменение алгоритма canonicalization разрешено только через `dna_schema_version` bump.
3. Производительность: утверждённые бюджеты p95/p99 и throughput соблюдаются без скрытой деградации.
4. Наблюдаемость: каждый критичный сбой фиксируется через `observability_gap.*` с runbook.
5. Безопасный rollout: новый DNA Core вводится только через canary + feature-flag + быстрый rollback.

## Этап 0 — Формальная спецификация до кодирования
### Сделать
- Зафиксировать формальную модель кластеризации DNA в `docs/contracts/v2/dna_model/`.
- Описать инварианты: детерминизм, сходимость (если включена), обработка дубликатов, пропусков и reorder.
- Зафиксировать mapping модель -> код (`core/src/main.rs` функции canonicalization/signature/clustering).

### Проверка (pass/fail)
- `docs/contracts/v2/dna_model/dna_core_clusterization.tla` существует и содержит явные инварианты.
- `docs/contracts/v2/dna_model/dna_core_clusterization.cfg` существует и задаёт model-checker параметры.
- `docs/contracts/v2/dna_model/README.md` содержит секцию "Code Mapping".

### Артефакт
- TLA+ model + CFG + README mapping.

## Этап 1 — Property-based и mutation-resilience раннего ядра
### Сделать
- Включить property-based тесты для DNA canonicalization/signature.
- Ввести heavy gate на `1 000 000` прогонов для детерминизма.
- Зафиксировать mutation-resilience policy: изменение критичных правил canonicalization должно ломать хотя бы один deterministic тест.

### Проверка (pass/fail)
- `cargo test -p art-core dna_property_determinism_proptest` PASS.
- `cargo test -p art-core dna_property_determinism_million_sequences_gate -- --ignored` PASS.
- `cargo test -p art-core dna_mutation_resilience_sentinel_test` PASS.
- `scripts/ci/run_stage29_dna_tests.sh` PASS.
- `scripts/ci/run_stage29_dna_property_million.sh` PASS.

### Артефакт
- Логи stage29 jobs + test output.

## Этап 2 — Раннее нагрузочное тестирование и профилирование
### Сделать
- Определить baseline-профили трафика: steady, burst, skewed keys, large payload attributes.
- Минимальные режимы прогона: `10k/сек` и `100k/сек`.
- Зафиксировать профилирование CPU/heap (perf/flamegraph/pprof-compatible output).

### Проверка (pass/fail)
- Отчёт stage34 содержит p95/p99, throughput, CPU hot paths, memory hot paths.
- Для overload 2x/3x зафиксирована стратегия деградации и предсказуемость latency.

### Артефакт
- `docs/source/perf_load_coverage_v0_2.md` + perf reports из CI.

## Этап 3 — CI красная черта (determinism/perf)
### Сделать
- Сделать CI-gates обязательными для merge:
  - `stage29-dna-assurance-gate`
  - `stage29-dna-tests`
  - `stage29-dna-property-million`
  - `stage34-perf-load-tests`
- Зафиксировать ratchet: ухудшение ключевых перф-метрик > `5%` запрещено.

### Проверка (pass/fail)
- `.github/workflows/ci.yml` содержит перечисленные jobs.
- `coverage-ratchet-gate` и perf gates блокируют регрессии.

### Артефакт
- CI workflow diff + успешные прогоны.

## Этап 4 — Эталонная реализация (reference) и паритет
### Сделать
- Поддерживать эталонное описание алгоритма canonicalization/signature (slow-but-correct).
- Поддерживать reference script: `scripts/tests/dna_reference_impl.py`.
- Сравнивать результат основной реализации с reference на детерминированном корпусе.

### Проверка (pass/fail)
- `cargo test -p art-core dna_reference_implementation_parity_corpus` PASS.
- При расхождении генерируется событие `observability_gap.dna_reference_mismatch`.

### Артефакт
- Логи parity тестов + runbook.

## Этап 5 — Мониторинг детерминизма в production
### Сделать
- Ввести двойной расчёт на canary/validator узле (или shadow pipeline).
- Ввести периодический replay исторического окна и сравнение с сохранёнными кластерами.

### Проверка (pass/fail)
- При расхождении генерируются события:
  - `observability_gap.dna_determinism_violation`
  - `observability_gap.dna_replay_mismatch`
- Для каждого события есть запись в registry и runbook.

### Артефакт
- Dashboard/alert proof + incident examples + runbooks.

## Этап 6 — Поэтапный rollout (feature-flag + canary)
### Сделать
- Ввести feature flag `dna_core_v2_enabled`.
- В canary режиме сравнивать old/new results (или new/reference).
- При divergence автоматически стопать rollout и выполнять rollback.

### Проверка (pass/fail)
- Есть canary protocol с порогами и stop conditions.
- Divergence генерирует `observability_gap.dna_canary_divergence`.

### Артефакт
- `docs/ops/console_linux_prod_readiness.md` + canary logs.

## Этап 7 — Автоматизированная remediation-петля
### Сделать
- На расхождение автоматически формировать reproducible fixture и тест.
- Блокировать promotion до PASS full regression.
- Фиксировать RCA и обновление model/spec при каждом детерминизм-инциденте.

### Проверка (pass/fail)
- Incident workflow включает: diff -> fixture -> regression test -> patch -> rerun all gates.
- CHECKLIST_38 не допускает закрытия этапов при открытом deterministic incident.

### Артефакт
- Incident package: fixture + test + patch reference + rerun logs.

## Обязательные observability-gap события
- `observability_gap.dna_determinism_violation`
- `observability_gap.dna_reference_mismatch`
- `observability_gap.dna_canary_divergence`
- `observability_gap.dna_replay_mismatch`

## Запреты
- Запрещён merge изменений DNA Core без прохождения stage29 DNA gates.
- Запрещён production rollout при активном divergence alert.
- Запрещено отключать heavy gate `dna_property_determinism_million_sequences_gate` в CI.
