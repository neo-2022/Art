# Source Coverage Packs

## Source of truth
- `docs/packs/spec.md`
- `docs/source/connected_system_visibility_v0_2.md`
- `docs/source/checklists/CHECKLIST_19_PACKS_FRAMEWORK.md`
- `docs/source/checklists/CHECKLIST_20_PACK_REGART.md`

## Назначение
Этот документ фиксирует, что каждый pack обязан не только "устанавливаться", но и объяснять:
- какие внешние системы он подключает;
- какие типы данных обещает передавать;
- какими receiver kinds и endpoint-механизмами Art увидит эти данные;
- как operator увидит сам факт подключения системы.

Документ обязан быть понятен не только автору pack, но и человеку, который будет сопровождать интеграцию позже. Поэтому термины `service_inventory`, `signal_coverage_claims`, `connected_system_projection` и другие поля здесь раскрываются простым языком, а не оставляются как внутренние метки манифеста.

## Обязательные поля pack coverage
Каждый pack с внешней интеграцией обязан содержать в `manifest.yaml`:
- `service_inventory`
- `receiver_examples`
- `signal_coverage_claims`
- `telemetry_endpoints`
- `regulatory_tags`
- `connected_system_projection`

## Что значит каждое поле
- `service_inventory` — список систем и компонентов, которые pack реально вводит в контур Art.
- `receiver_examples` — какими receiver kinds нужно снимать сигналы с этой системы.
- `signal_coverage_claims` — какие типы данных система обещает отдавать и какие Art реально ожидает увидеть.
- `telemetry_endpoints` — какие входные/выходные точки участвуют в передаче данных.
- `regulatory_tags` — специальные режимы и ограничения (например, partner-exposed, internal_service, ru_profile).
- `connected_system_projection` — как именно эта система должна появиться в Connected System View.

## Обязательная связь с Connected System View
Если pack не даёт достаточной service inventory и coverage claims, оператор не сможет понять:
- подключилась система или нет;
- какие данные реально идут;
- какие данные только обещаны;
- где drift между обещанным и фактическим.

Поэтому source coverage pack считается неполным без явной поддержки:
- `produced_data_kinds`
- `declared_data_kinds`
- `observed_data_kinds`
- `receiver_kinds`
- `telemetry_endpoints`
- `active_gap_events`
- `connected_system_projection`

## Пример: Pack REGART

| system_id | display_name | integration_kind | produced_data_kinds | declared_data_kinds | observed_data_kinds | receiver_examples | telemetry_endpoints | active_gap_events | connected_system_projection | regulatory_tags |
|---|---|---|---|---|---|---|---|---|---|---|
| `regart-browser-level0` | `REGART Browser Level0` | `browser_level0` | `ui_runtime`, `browser_error`, `bridge_backlog_status` | `ui_runtime`, `browser_error`, `bridge_backlog_status` | `ui_graph_empty`, `network_error`, `upstream_error` | `file_tail`, `stdout_stderr`, `net_probe` | `/api/v1/ingest`, `/api/v1/incidents` | `observability_gap.connected_system_not_visible`, `observability_gap.connected_system_coverage_drift` | `declared_only -> connected/degraded` по свежим browser/runtime signals | `partner_exposed`, `browser_surface` |
| `regart-ui-proxy` | `REGART UI Proxy` | `ui_proxy` | `proxy_upstream`, `proxy_health`, `http_status`, `systemd_state`, `journald_log` | `proxy_upstream`, `proxy_health`, `http_status` | `ui_proxy_unavailable`, `upstream_error` | `journald`, `systemd_unit`, `net_probe` | `/api/v1/ingest`, `/api/v1/incidents` | `observability_gap.connected_system_not_visible`, `observability_gap.connected_system_coverage_drift` | `declared_only -> connected/degraded` по proxy/systemd signals | `partner_exposed`, `internal_service` |
| `regart-langgraph-runtime` | `REGART LangGraph Runtime` | `langgraph_runtime` | `langgraph_run`, `tool_event`, `model_event`, `graph_event`, `process_probe` | `langgraph_run`, `tool_event`, `model_event`, `graph_event` | `tools_event`, `models_event`, `graph_event` | `journald`, `stdout_stderr`, `proc_probe` | `/api/v1/ingest`, `/api/v1/incidents` | `observability_gap.connected_system_not_visible`, `observability_gap.connected_system_coverage_drift` | `declared_only -> connected/degraded` по runtime and graph signals | `partner_exposed`, `internal_service` |

## Условие полноты
Pack source coverage считается полной только если:
1. manifest содержит все обязательные поля;
2. docs объясняют declared coverage;
3. runtime harness может доказать observed coverage;
4. Connected System View умеет показать эту систему человеку.
