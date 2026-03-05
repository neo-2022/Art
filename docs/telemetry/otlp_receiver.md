# OTLP receiver

Лимиты:
- max_events_per_sec=200
- burst=400
- max_batch_events=200
- max_size_bytes=524288

Правила применения:
- входные лимиты применяются на входе OTLP receiver до преобразования в RawEvent;
- принимаются только OTLP logs;
- при срабатывании лимита возвращается backpressure (429/503/413) с `retry_after_ms >= 0`;
- при каждом срабатывании лимита генерируется `observability_gap.otlp_rate_limited`
  с evidence: `limit_name`, `current_value`, `retry_after_ms`, `endpoint`, `trace_id`.
