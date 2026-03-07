# Pack REGART

Pack REGART содержит fixtures событий и правила обработки для совместимости с Art.

Ключевые разделы:
- fixtures (полный набор событий)
- correlation (`run_id`, `trace_id`, `span_id`) без перезаписи
- examples конфигов receivers
- coverage matrix: `Browser Level0`, `UI Proxy`, `LangGraph`, `systemd`, `net_probe`
- pinned hostile harness как обязательное runtime-proof для partner-exposed REGART интеграции
- Connected System View: `REGART Browser Level0`, `REGART UI Proxy`, `REGART LangGraph Runtime`

## Connected System View

После подключения Pack REGART оператор обязан видеть в Art не только отдельные события, но и сами системы:
- `regart-browser-level0`
- `regart-ui-proxy`
- `regart-langgraph-runtime`

Для каждой из них должны быть видны:
- `connection_status`
- `declared_data_kinds`
- `observed_data_kinds`
- `receiver_kinds`
- `telemetry_endpoints`
- `active_gap_events`
- `evidence_refs`

Если Pack REGART установлен, но эти системы остаются невидимыми или видны только как `declared_only`,
integrated proof считается неполным.

Runtime-проверка через API Core:

```bash
bash scripts/tests/pack_regart_runtime_api.sh
```

Pinned external adversarial harness:
- `docs/source/regart_adversarial_integration_harness_v0_2.md`
- для stage20 без harness evidence pack proof считается неполным.
