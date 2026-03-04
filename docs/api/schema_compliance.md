# Schema compliance

| Spec requirement | Schema field/path | Status |
|---|---|---|
| RawEvent severity | raw_event.severity | done |
| Ingest endpoints v1 | openapi paths /api/v1/* | done |
| invalid_details index/reason | ingest_response.invalid_details[] | done |
| Backpressure 413/429/503 + retry_after_ms | openapi BackpressureError.retry_after_ms | done |
| ack.upto_seq contract | ingest_response.ack.upto_seq | done |
