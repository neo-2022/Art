# Runbook: unsafe startup config refused

## Сигналы
- `observability_gap.unsafe_startup_config_refused`
- отказ `ready` state или отказ старта компонента

## Диагностика
1. Определить `component`, `config_key` и `reason`.
2. Проверить deployment profile и transport/security policy.
3. Убедиться, что проблема не вызвана drift между profile и runtime env.

## Ремедиация
1. Исправить unsafe-конфиг, а не обходить validator.
2. Если нужен override, он должен быть временным, явным и с audit/evidence.
3. Повторно запустить startup validation.

## Проверка
- компонент стартует без override bypass
- `ready` state достигается только на безопасной конфигурации
