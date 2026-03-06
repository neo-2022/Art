# Receiver Source Coverage

## Source of truth
- `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md`
- `docs/source/agent_deployment_transport_v0_2.md`

| Класс источника | receiver_kind | mechanism | source_id_pattern | persistence_mode | gap_events | privacy_boundary |
|---|---|---|---|---|---|---|
| journald/systemd | `journald`, `systemd_unit` | journal cursor + systemd state transitions | `journald:<unit_or_matcher_id>`, `systemd:<unit_name>` | cursor/state + spool/outbox | `receiver_read_failed`, `receiver_permission_denied` | redaction до spool |
| files/logs | `file_tail` | tail + rotation | `file:<abs_path>` | offset + spool/outbox | `receiver_permission_denied`, `receiver_read_failed` | redaction до spool |
| stdout/stderr wrapper | `stdout_stderr` | wrapper process pipes | `proc:<command_id>` | source_seq + spool/outbox | `receiver_process_spawn_failed`, `receiver_process_exited` | redaction до spool |
| process probes | `proc_probe` | pid/cpu/rss sampling | `proc:<target_name>` | source_seq + spool/outbox | `receiver_probe_failed`, `receiver_target_unreachable` | redaction до spool |
| port/network/http probes | `net_probe` | tcp/http reachability and latency | `net:<target_name>` | source_seq + spool/outbox | `receiver_probe_failed`, `receiver_target_unreachable` | redaction до spool |
| OTLP logs | `otlp_logs` | sidecar ingress | `otlp:<listener_id>` | source_seq + spool/outbox | `receiver_config_invalid`, `receiver_read_failed` | redaction до spool |
