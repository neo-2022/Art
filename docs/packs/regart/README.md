# Pack REGART

Pack REGART содержит fixtures событий и правила обработки для совместимости с Art.

Ключевые разделы:
- fixtures (полный набор событий)
- correlation (`run_id`, `trace_id`, `span_id`) без перезаписи
- examples конфигов receivers
- coverage matrix: `Browser Level0`, `UI Proxy`, `LangGraph`, `systemd`, `net_probe`
- pinned hostile harness как обязательное runtime-proof для partner-exposed REGART интеграции

Runtime-проверка через API Core:

```bash
bash scripts/tests/pack_regart_runtime_api.sh
```

Pinned external adversarial harness:
- `docs/source/regart_adversarial_integration_harness_v0_2.md`
- для stage20 без harness evidence pack proof считается неполным.
