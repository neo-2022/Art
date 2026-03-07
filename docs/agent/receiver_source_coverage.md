# Receiver Source Coverage

## Source of truth
- `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md`
- `docs/source/agent_deployment_transport_v0_2.md`

| Класс источника | receiver_kind | mechanism | source_id_pattern | persistence_mode | produced_data_kinds | connected_system_projection | gap_events | privacy_boundary |
|---|---|---|---|---|---|---|
| journald/systemd | `journald`, `systemd_unit` | journal cursor + systemd state transitions | `journald:<unit_or_matcher_id>`, `systemd:<unit_name>` | cursor/state + spool/outbox | `systemd_state`, `journald_log`, `service_failure`, `restart_loop` | подтверждает существование системы, её runtime state и переводит Connected System View из `declared_only` в `connected/degraded` | `receiver_read_failed`, `receiver_permission_denied` | redaction до spool |
| files/logs | `file_tail` | tail + rotation | `file:<abs_path>` | offset + spool/outbox | `app_log`, `proxy_log`, `integration_log` | подтверждает observed coverage для логовых типов данных и помогает выявить drift между promised и observed | `receiver_permission_denied`, `receiver_read_failed` | redaction до spool |
| stdout/stderr wrapper | `stdout_stderr` | wrapper process pipes | `proc:<command_id>` | source_seq + spool/outbox | `stdout_event`, `stderr_event`, `runtime_error` | подтверждает живой runtime приложения и переводит систему в `degraded`, если виден только stderr/error поток | `receiver_process_spawn_failed`, `receiver_process_exited` | redaction до spool |
| process probes | `proc_probe` | pid/cpu/rss sampling | `proc:<target_name>` | source_seq + spool/outbox | `process_probe`, `resource_usage`, `pid_presence` | доказывает, что система или её runtime-компонент реально присутствует, даже если бизнес-события ещё не пришли | `receiver_probe_failed`, `receiver_target_unreachable` | redaction до spool |
| port/network/http probes | `net_probe` | tcp/http reachability and latency | `net:<target_name>` | source_seq + spool/outbox | `net_probe`, `health_status`, `latency`, `http_status` | показывает доступность и transport health системы; при проблеме переводит статус в `degraded` и поднимает coverage drift | `receiver_probe_failed`, `receiver_target_unreachable` | redaction до spool |
| OTLP logs | `otlp_logs` | sidecar ingress | `otlp:<listener_id>` | source_seq + spool/outbox | `otlp_log`, `trace_correlated_log`, `structured_runtime_event` | доказывает, что система реально отдаёт структурированные telemetry-сигналы и заполняет observed data kinds без догадок | `receiver_config_invalid`, `receiver_read_failed` | redaction до spool |
