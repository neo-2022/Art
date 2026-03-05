# MCP runtime modes

Режимы:
- `read_only`
- `limited_actions`
- `full_admin`

Поведение:
- `read_only`: `POST /api/v1/actions/execute` всегда deny.
- `limited_actions`: разрешён только allowlist действий.
- `full_admin`: действия разрешаются по RBAC.

Любой deny по MCP режиму генерирует `security.access_denied`.

