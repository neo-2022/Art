# Upstream error format

Единый формат:
- `what` — human-readable description of the failure.
- `where` — logical component or endpoint that emitted the error (e.g., `Art.actions.execute`).
- `why` — explicit classification (timeout, bad response, invalid schema, auth failure).
- `actions` — recommended response (retry, alert, inspect logs).
- `evidence` — log snippet, HTTP code, provider payload, etc.
- `trace_id` — correlation id текущего запроса.
- `retry_count` — целое число `>= 0` (номер попытки текущего хопа).

Пример RawEvent:
```
{
  "kind": "upstream_error",
  "trace_id": "1234",
  "retry_count": 2,
  "what": "Art action rejected payload",
  "where": "Art.actions.execute",
  "why": "invalid_payload",
  "actions": ["refresh-config", "notify-ops"],
  "evidence": {
    "http_status": 422,
    "response": {"error":"invalid schema"}
  }
}
```

Каждый upstream error содержит `trace_id` и `retry_count >= 0`: `retry_count` увеличивается при повторных попытках и попадает в observability-события `observability_gap.upstream_error`.
