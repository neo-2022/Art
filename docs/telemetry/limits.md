# Telemetry limits

| limit | value |
|---|---|
| max_events_per_sec | 200 |
| burst | 400 |
| max_batch_events | 200 |
| max_size_bytes | 524288 |

Применение: лимиты проверяются до преобразования OTLP в RawEvent.

Ссылки:
- `docs/telemetry/otlp_receiver.md`
- `docs/telemetry/otel_mapping.md`
