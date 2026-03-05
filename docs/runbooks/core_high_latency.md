# Runbook: core_high_latency

## mitigations
1. Проверить ingest load и блокировки storage.
2. Снизить входящий поток/включить backpressure.
3. Проверить p95 latency после мер.

## verification
- p95 `ingest_latency_ms` <= 500;
- incident `core.high_latency` закрыт.
