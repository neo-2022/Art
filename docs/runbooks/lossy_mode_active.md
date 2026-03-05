# Runbook: lossy_mode_active

## mitigations
1. Зафиксировать инцидент `lossy_mode_active` как минимум SEV1.
2. Проверить причину перехода в `drop_oldest_when_full` (перегрузка/сеть/ingest).
3. Восстановить throughput доставки и вернуть режим `never_drop_unacked`, если возможно.
4. Отработать DLQ и оценить объём фактической потери данных.

## verification
1. События `data_quality.lossy_outbox_drop` прекращаются в стабильном режиме.
2. Инцидент `lossy_mode_active` закрыт после стабилизации.
3. Счётчик `outbox_dropped_total` перестаёт расти.
