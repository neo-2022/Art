# Runbook: observability_gap.audit_merkle_verify_failed

## Symptoms
- Verify endpoint возвращает failed.
- UI audit chain показывает разрыв.

## Diagnosis
1. Проверить `audit_id/proof_hash/step/error`.
2. Запустить stage32 verify tests.
3. Проверить источник tampering.

## Resolution
1. Восстановить корректную chain последовательность.
2. Перестроить proof refs для затронутых записей.
3. Повторить verify tests.

## Rollback
- Отключить автоматический verify UI для затронутого диапазона до восстановления целостности.
