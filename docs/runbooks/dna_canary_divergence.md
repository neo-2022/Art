# Runbook: observability_gap.dna_canary_divergence

## Symptoms
- На canary узле результаты DNA отличаются от stable (или shadow/reference).
- Rollout gate блокирует расширение трафика.

## Diagnosis
1. Сверить build IDs canary/stable.
2. Проверить divergence sample (`dna_id`, `canonical_hash`, `payload_hash`).
3. Прогнать replay последнего окна событий на обоих build.

## Resolution
1. Немедленно остановить rollout.
2. Выполнить rollback до stable tag.
3. Открыть incident и приложить divergence fixture.
4. Разрешить повторный canary только после PASS stage29+stage34.
