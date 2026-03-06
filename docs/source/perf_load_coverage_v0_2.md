# Perf / Load / Coverage v0.2

Последняя актуализация: 2026-03-06

## Цель
Зафиксировать производственные бюджеты DNA Core и Console, запретить перф/coverage регрессии и обеспечить воспроизводимый load/soak контур.

## Перф-бюджеты (обязательные)
1. `ingest v2 p95 latency` <= 120 ms при профиле `10k/сек`.
2. `ingest v2 p95 latency` <= 350 ms при профиле `100k/сек`.
3. `snapshot v2 p95 latency` <= 200 ms.
4. `stream v2 p95 delivery lag` <= 250 ms.
5. `find similar by DNA p95` <= 50 ms (hot index), <= 150 ms (cold path).
6. `replay parity check` <= 5 min на окно 1h.
7. `weak-gpu picking p95` < 50 ms.
8. `weak-gpu scene update p95` < 50 ms.
9. `local-store index heap growth p95` <= 64 MB на профиль `local-store-heavy`.
10. `local-store analytics heap growth p95` <= 96 MB на профиль `local-store-heavy`.

## Профили нагрузки
- `steady-10k`: стабильный поток 10k/сек.
- `steady-100k`: стабильный поток 100k/сек.
- `burst-3x`: всплески 3x от текущего бюджета.
- `skewed-keys`: перекос по малому числу `kind/service`.
- `wide-payload`: события с большим числом атрибутов payload.
- `local-store-heavy`: массовые операции cache/index/analytics без блокировки UI thread.

## Local-stores law
- Тяжёлые операции local-stores выполняются только в Web Workers.
- Обновление индекса выполняется инкрементально.
- p95 latency операций index lookup/cache read в hot-path не выше 50 ms.
- p95 memory budget обязателен для cache/index/analytics/spatial adapters.

## Weak-GPU degradation law
- Для профиля Intel UHD 620 (и эквивалентного VM GPU) обязателен budget `p95 < 50 ms`.
- При риске нарушения budget применяется автоматическая деградация качества: LOD downshift + упрощённый рендер.

## Ratchet policy
- Ухудшение ключевых перф-метрик более 5% от зафиксированного baseline запрещено.
- Coverage baseline фиксируется в `coverage_ratchet_baseline_v0_2.json`.
- Снижение coverage baseline запрещено.
- Для `apps/console-web` и `packages/*` target 100% lines/branches/functions.

## Обязательные отчёты
- Load report: p50/p95/p99 + throughput + error-rate.
- Profile report: CPU hotspots + memory hotspots + remediation list.
- Soak report: backlog/recovery + zero-loss.
- Regression report: сравнение с прошлым baseline и delta по метрикам.

## Проверка
- `bash scripts/tests/stage34_perf_load_smoke.sh`
- `bash scripts/ci/check_coverage_ratchet_v0_2.sh`
- Stage34 CI jobs (`stage34-perf-load-tests`, `coverage-ratchet-gate`)
