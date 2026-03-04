# Art Agent Spool/Outbox v1

## Назначение
Spool хранит события локально до подтверждённой доставки в Core ingest. Outbox делает ретраи с backoff и не теряет unacked события в default режиме.

## Контракт
- Политика переполнения по умолчанию: `spool_overflow_policy=never_drop_unacked`.
- Альтернатива через конфиг: `spool_overflow_policy=drop_oldest_when_full`.
- Приём в spool ведётся до `capacity_bytes`; при переполнении поведение определяется политикой.
- Flush в Core привязан к ack (`ack.upto_seq`) и удаляет только подтверждённые записи.

## Метрики
- `spool_pending_total`
- `spool_flushed_total`
- `spool_dropped_total` (растёт только в `drop_oldest_when_full`)

## События
- `observability_gap.spool_full`
- `observability_gap.spool_corrupted`
- `observability_gap.spool_disk_full`
- `data_quality.lossy_spool_drop`
