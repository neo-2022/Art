# State файлы receivers

## file_tail
- state key: `offset`
- формат: JSON
- пример:

```json
{
  "source_id": "file:/var/log/my-service.log",
  "offset": 18432
}
```

## journald
- state key: `cursor`
- формат: JSON
- пример:

```json
{
  "source_id": "journald:my_langgraph_agent.service",
  "cursor": "s=6d3b8f5d...;i=7f7;b=...;m=...;t=...;x=..."
}
```

## systemd_unit / proc_probe / net_probe / stdout_stderr / otlp_logs
- допустимый формат state: JSON
- хранится минимум:
  - `source_id`
  - `source_seq`
  - transport-related replay metadata при наличии

## Общее правило
- state должен переживать перезапуск агента;
- spool/outbox boundary и delivery/replay law описаны в `docs/source/agent_deployment_transport_v0_2.md`.
