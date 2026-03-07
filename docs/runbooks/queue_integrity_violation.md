# Runbook: queue integrity violation

## Сигналы
- `observability_gap.queue_integrity_violation`
- duplicate flood
- anti-loop trip
- runaway backlog growth

## Диагностика
1. Проверить `queue_name`, `source_id`, `violation_type`.
2. Проверить, не зациклился ли replay/bridge path.
3. Проверить seq-consistency и duplicate ratio.
4. Проверить, не вызвана ли проблема одним noisy source или tenant.

## Ремедиация
1. Перевести queue path в controlled degraded mode.
2. Изолировать источник или tenant, который создаёт нарушение.
3. Включить quarantine/dead-letter для неисправимого потока.
4. Восстановить monotonic order и подтвердить normal replay.

## Проверка
- duplicate/loop signal прекратился
- backlog стабилизировался в budget
- replay и delivery снова монотонны
