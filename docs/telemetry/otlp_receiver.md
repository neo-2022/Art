# OTLP receiver

Лимиты:
- max_events_per_sec=200
- burst=400
- max_batch_events=200
- max_size_bytes=524288

Входные лимиты применяются до преобразования в RawEvent.
Принимаются только OTLP logs.
