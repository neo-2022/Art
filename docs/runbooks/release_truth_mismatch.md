# Runbook: release_truth_mismatch

## Что это означает
Release metadata, `GO/NO-GO`, `CHANGELOG`, `RELEASE_CHECKLIST` или delivery evidence расходятся с реальным состоянием релиза.

## Что проверить
1. Актуален ли commit/tag.
2. Совпадает ли evidence с текущей ревизией.
3. Нет ли stale release claims.
4. Не сказано ли в документах больше, чем реально доказано.

## Что делать
1. Остановить rollout.
2. Обновить release docs и decision record.
3. Повторить release truth checks.
4. Возобновлять rollout только после устранения рассинхрона.

## Проверка восстановления
- release docs, evidence и runtime truth снова согласованы.
