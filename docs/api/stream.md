# Stream API v1

## Endpoint
`GET /api/v1/stream`

## Cursor model
- Cursor передаётся через заголовок `Last-Event-ID`.
- Значение `Last-Event-ID` интерпретируется как `seq` (`u64`).
- Retention window фиксирован: `86400000` ms (24h).

## Too old -> snapshot
Если `Last-Event-ID` меньше `min_retained_seq` и не равен `0`, сервер отвечает snapshot:
- HTTP 200
- `Content-Type: application/json`
- заголовок `X-Stream-Cursor: <new_cursor>`
- тело полностью соответствует `/api/v1/snapshot`.

Пример:
- request: `Last-Event-ID: 1`
- response headers: `X-Stream-Cursor: 42`

Клиент после этого обязан переподключиться к `/api/v1/stream` с `Last-Event-ID=<new_cursor>`.

## Valid cursor -> SSE
Если cursor валиден (`Last-Event-ID >= min_retained_seq`) или `Last-Event-ID: 0`, сервер отвечает SSE:
- `Content-Type: text/event-stream`
- `Cache-Control: no-cache`
- `id:` равен `seq` события и монотонно возрастает для backlog.

## Gzip
При `Accept-Encoding: gzip` сервер выставляет `Content-Encoding: gzip`.
