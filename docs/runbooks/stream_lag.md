# Runbook: stream_lag

## symptoms
- В snapshot появляются `observability_gap.stream_lag`.
- Lag превышает порог 5000 мс.

## checks
- Проверить backlog и ingest скорость.
- Проверить доступность storage и I/O задержки.
- Проверить CPU/RAM Core.

## mitigations
- Снизить ingest rate.
- Увеличить ресурсы Core (CPU/RAM/IOPS).
- Временно ограничить число подписчиков.

## rollback
- Откатить последние изменения stream/pipeline.
- Вернуть стабильные лимиты и конфигурацию.

## verification
- `stream_lag_ms` p95 <= 2000 мс на smoke/load.
- Новые `observability_gap.stream_lag` не генерируются в стабильном режиме.
- Подписчики получают поток без накопления задержки.

## escalation
- Эскалировать SRE on-call при lag >5000 мс дольше 5 минут.
