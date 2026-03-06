# Runbook: observability_gap.investigation_replay_failed

## Symptoms
- Replay InvestigationDoc завершается ошибкой.
- Fork/compare несовместимы по версии.

## Diagnosis
1. Проверить `doc_id/doc_version/step/error`.
2. Запустить stage31 replay tests.
3. Сверить compatibility matrix.

## Resolution
1. Исправить parser/serializer compatibility.
2. Мигрировать документ в поддерживаемую версию.
3. Повторить replay tests.

## Rollback
- Временно использовать предыдущий parser и отключить replay новых версий.
