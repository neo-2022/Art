# Runbook: observability_gap.truth_mode_misuse

Событие: `observability_gap.truth_mode_misuse`  
Компонент: `console/truth-mode`

## Symptoms
- UI карточка в режиме `observed` отображается без `evidence_refs`.
- `predicted` элементы визуально неотличимы от фактических.
- Truth-mode suite падает на invariant checks.

## Diagnosis
1. Проверить payload `meta.truth_mode` и `meta.evidence_refs`.
2. Для `observed` подтвердить `evidence_refs_count > 0`.
3. Проверить `lineage_hash` и связность lineage chain.
4. Сверить UI badge mapping и schema constraints.

## Resolution
1. Заблокировать рендер спорного элемента как факта.
2. Исправить mapping truth-mode в producer/adapter.
3. Перезапустить `stage30-truth-modes-tests`.
4. Подтвердить PASS и отсутствие повторных misuse событий.
