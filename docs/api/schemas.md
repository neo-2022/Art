# Art schemas v1

Source index: `docs/schemas/index.md`

## Schemas
- `docs/schemas/v1/raw_event.json` — `RawEvent`: fields `schema_version, severity`.
- `docs/schemas/v1/ingest_envelope.json` — `IngestEnvelope`: fields `events`.
- `docs/schemas/v1/ingest_response.json` — `IngestResponse`: fields `accepted, ack, invalid_details`.
- `docs/schemas/v1/incident.json` — `Incident`: fields `id, severity, status`.

Generated from docs/schemas/index.md and docs/schemas/v1/*.json.
