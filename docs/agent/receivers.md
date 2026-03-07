# Art Agent Receivers v1

## `receiver_kind` (фиксированный enum)
- `file_tail`
- `journald`
- `systemd_unit`
- `proc_probe`
- `net_probe`
- `stdout_stderr`
- `otlp_logs`

## Контракт RawEvent от receivers
- `source_id` (string, уникален в рамках агента)
- `source_seq` (int >= 0, монотонный для данного `source_id`)
- `source_ts_ms` (int >= 0)
- `receiver_kind` (enum)
- `trace_id` (всегда присутствует; генерируется при отсутствии)
- `retry_count` (int >= 0, всегда присутствует)

## Правило source_id
- `file_tail` -> `file:<abs_path>`
- `journald` -> `journald:<unit_or_matcher_id>`
- `systemd_unit` -> `systemd:<unit_name>`
- `proc_probe` -> `proc:<target_name>`
- `net_probe` -> `net:<target_name>`
- `stdout_stderr` -> `proc:<command_id>`
- `otlp_logs` -> `otlp:<listener_id>`

## Delivery path
Обязательный путь:

`receiver -> normalizer -> pre-write redaction -> spool/outbox -> transport -> Core ingest -> ack`

## Backpressure
- При `never_drop_unacked`: receiver pause + `observability_gap.receiver_paused_spool_full`.
- При `drop_oldest_when_full`: чтение продолжается + lossy события.

## Deployment boundary
Модели установки и доставки вынесены в:
- `docs/source/agent_deployment_transport_v0_2.md`
- `docs/ops/agent_multisite_deploy.md`
