# Actions API

`POST /api/v1/actions/execute` выполняет действие только после RBAC и MCP runtime enforcement.

Минимальный payload:

```json
{
  "action": "service.restart",
  "target": "core",
  "params": {
    "key": "value"
  }
}
```

Ответ:
- `200` при `success`
- `403` при `denied` (RBAC/MCP), с генерацией `security.access_denied`

