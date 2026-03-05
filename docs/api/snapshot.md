# Snapshot API v1

## Endpoint
`GET /api/v1/snapshot`

## Response
HTTP 200, JSON:
- `cursor` - текущий максимальный `seq`
- `min_retained_seq` - минимальный `seq`, доступный в retention окне (24h)
- `events[]` - список событий (включая `observability_gap.*`)
- `incidents[]` - текущие incidents

## Cursor handoff
При ответе `/api/v1/stream` в режиме `too old -> snapshot`, клиент использует `X-Stream-Cursor` как новый cursor для последующего SSE-подключения.
