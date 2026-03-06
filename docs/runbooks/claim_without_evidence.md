# Runbook: observability_gap.claim_without_evidence

## Symptoms
- UI/API пытается показать claim без `evidence_refs`.
- Нарушение закона Evidence-First.

## Diagnosis
1. Проверить `claim_id/component/rule`.
2. Запустить `corepack pnpm --filter @art/ui-laws run test`.
3. Проверить источник данных claim.

## Resolution
1. Запретить render claim без evidence_refs.
2. Исправить producer claim payload.
3. Повторить stage30 tests.

## Rollback
- Включить hard-block claims UI section до исправления producer.
