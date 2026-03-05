# Audit (append-only)

Audit журнал хранит записи только в режиме append-only.

Обязательные поля записи:
- `timestamp`
- `actor_id`
- `actor_role`
- `mcp_mode`
- `action`
- `target`
- `result` (`success|denied|error`)
- `trace_id`
- `evidence_ref`
- `client_ip`
- `user_agent`

Правила:
- `client_ip` нормализуется (IPv4 с нулевым последним октетом, IPv6 /48).
- `user_agent` фильтруется и ограничивается до 256 символов.
- update/delete audit запрещены (append-only).

