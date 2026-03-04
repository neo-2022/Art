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
