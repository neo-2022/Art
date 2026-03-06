# Runbook: observability_gap.dna_traceability_gap

## Symptoms
- Невозможно объяснить формирование DNA для конкретного инцидента.
- Replay/time-window не воспроизводит trace решений.

## Diagnosis
1. Проверить наличие decision-trace по dna_id.
2. Проверить replay consistency на том же окне.
3. Сверить версию canonicalization и build_id.

## Resolution
1. Переключить incident в режим обязательного trace capture.
2. Восстановить trace pipeline и повторить replay.
3. Добавить regression fixture для данного кейса.
