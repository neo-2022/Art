# API errors

- `invalid_details` всегда присутствует в ingest-ответе.
- `invalid_details[]` содержит: index, reason, path, code.
- backpressure ответы (413/429/503) содержат `retry_after_ms`.

Коды `invalid_details.code`:
- validation_error
- schema_mismatch
- payload_too_large
- internal_error
