# Ingest protocol v1

`POST /api/v1/ingest` принимает batch.

- Для принятых событий назначается монотонный `seq`.
- В каждом ответе присутствует `ack.upto_seq` (>=0).
- `invalid_details` присутствует всегда.

Пример запроса:
```json
{
  "events": [
    {"severity": "info", "msg": "ok"},
    {"msg": "invalid"}
  ]
}
```

Пример ответа:
```json
{
  "ack": {"upto_seq": 42},
  "accepted": 1,
  "invalid": 1,
  "invalid_details": [
    {"index": 1, "reason": "missing severity", "path": "severity", "code": "validation_error"}
  ]
}
```
