# Runbook: authenticity_policy_violation

## Что это означает
В baseline проекта найден asset или контент без допустимого provenance/legal основания.

## Что проверить
1. Путь к asset.
2. Его тип и происхождение.
3. Есть ли allowlist entry.
4. Не попал ли он из demo/showcase/user upload contour.

## Что делать
1. Удалить или quarantine спорный asset.
2. Заменить его project-owned или generated аналогом.
3. Обновить provenance/allowlist только при наличии реального основания.

## Проверка восстановления
- authenticity gate снова проходит;
- asset surface legal-safe и provenance-aware.
