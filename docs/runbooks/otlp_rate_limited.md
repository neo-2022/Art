# Runbook: otlp_rate_limited

## symptoms
- рост 429/503/413 на OTLP endpoint
- событие `observability_gap.otlp_rate_limited` появляется в snapshot/stream

## checks
- проверить `limit_name`, `current_value`, `retry_after_ms`, `endpoint`, `trace_id` в событии
- сверить фактический поток с лимитами (`max_events_per_sec`, `burst`, `max_batch_events`, `max_size_bytes`)

## mitigations
- снизить входной поток OTLP с источника
- уменьшить размер batch/частоту отправки
- временно увеличить capacity receiver (если допустимо по профилю)

## rollback
- вернуть штатные лимиты после стабилизации потока
- подтвердить отсутствие новых событий `observability_gap.otlp_rate_limited`

## verification
- форсировать короткий тестовый burst и проверить ожидаемый backpressure статус
- убедиться, что `retry_after_ms` возвращается в ответе
- убедиться, что событие видно в snapshot/stream с полным evidence

## escalation
- если срабатывание длится >15 минут, эскалировать в on-call SEV2
