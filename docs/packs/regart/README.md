# Pack REGART

Pack REGART содержит fixtures событий и правила обработки для совместимости с Art.

Ключевые разделы:
- fixtures (полный набор событий)
- correlation (`run_id`, `trace_id`, `span_id`) без перезаписи
- examples конфигов receivers

Runtime-проверка через API Core:

```bash
bash scripts/tests/pack_regart_runtime_api.sh
```
