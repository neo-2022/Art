# Runbook: observability_gap.dna_replay_mismatch

## Symptoms
- Ночной/периодический replay исторического окна не совпал с сохранёнными кластерами.

## Diagnosis
1. Зафиксировать окно времени и `effective_profile_id`.
2. Сравнить baseline snapshot с replay snapshot по `dna_id` и counts.
3. Проверить изменения в canonicalization/migration после момента записи.

## Resolution
1. Пересчитать affected window и пометить stale derived artifacts.
2. При необходимости включить read-only degraded mode для зависимых views.
3. Выпустить фикс и повторно пройти replay consistency suite.
4. Обновить RCA и regression fixtures.
