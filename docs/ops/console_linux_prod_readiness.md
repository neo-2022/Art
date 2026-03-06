# Console Linux Production Readiness

Последняя актуализация: 2026-03-06

## Цель
Фиксировать обязательный прогон Linux readiness для Tier B Console перед rollout.

## Обязательная команда

```bash
bash scripts/tests/console_linux_prod_readiness.sh
```

## Обязательные проверки
1. EN default + RU switch
2. Surface routing (7 surfaces)
3. One-click-to-evidence
4. API v1/v2 compatibility read-path
5. Degradation mode markers under partial API failures
6. DNA canary divergence monitor включён
7. Feature flag `dna_core_v2_enabled` переключает fallback raw-events mode без падения Console
8. Privacy alert gate по evidence access anomalies включён

## Rollout protocol
1. canary 1 instance
2. readiness suites
3. dna divergence gate check
4. privacy alert gate check
5. alert gate check
6. expand rollout

## Rollback protocol
1. rollback to previous stable tag
2. rerun readiness suite
3. verify snapshot/stream consistency
4. keep `dna_core_v2_enabled=0` until stage29/34 gates PASS
