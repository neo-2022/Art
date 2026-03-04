# Source stale

Критерий stale:
- `now_ms - source_last_seen_ms > 600000`.

Событие:
- `observability_gap.source_stale`
- evidence_min: source_id, age_ms, threshold_ms=600000, trace_id
- попадает в snapshot/stream
