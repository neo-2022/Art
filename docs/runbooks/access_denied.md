# Runbook: access_denied

Событие: `security.access_denied`

## mitigations
- Проверить `actor_role` и соответствие RBAC матрице.
- Проверить `mcp_mode` (`read_only`, `limited_actions`, `full_admin`).
- Для `limited_actions` проверить allowlist и требуемый `action`.

## verification
- Повторить запрос с корректной ролью/режимом.
- Убедиться, что API возвращает `200`.
- Убедиться, что в stream/snapshot нет новых `security.access_denied` для того же сценария.

