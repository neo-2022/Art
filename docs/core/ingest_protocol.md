# Ingest protocol v1

`POST /api/v1/ingest` принимает batch.

- Для принятых событий назначается монотонный `seq`.
- В каждом ответе присутствует `ack.upto_seq` (>=0).
- `invalid_details` присутствует всегда.

Пример ответа:
```json
{"ack": {"upto_seq": 42}, "invalid_details": []}
```
