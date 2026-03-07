# Runbook: guard self-test failed

## Сигналы
- `observability_gap.guard_self_test_failed`
- missing heartbeat или failed self-check у guard-а

## Диагностика
1. Определить `guard_name` и `failure_mode`.
2. Проверить последнюю успешную self-check запись.
3. Выяснить, guard сломан логически, инфраструктурно или документарно.

## Ремедиация
1. Остановить зависимые stage/release решения, если guard критичен.
2. Починить сам guard, а не только его потребителя.
3. Повторно выполнить self-test и regression path.

## Проверка
- self-test снова зелёный
- heartbeat восстановлен
- зависимый контур разблокирован только после доказанного восстановления
