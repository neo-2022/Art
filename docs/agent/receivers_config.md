# Конфиг receivers v1

```yaml
receivers:
  - kind: file_tail
    file_tail:
      path: /var/log/my-service.log
      multiline: true

  - kind: journald
    journald:
      unit: my_langgraph_agent.service

  - kind: systemd_unit
    systemd_unit:
      unit: art-core.service

  - kind: proc_probe
    proc_probe:
      target_name: art-core
      pid_file: /run/art-core.pid

  - kind: net_probe
    net_probe:
      target_name: art-core-health
      url: http://127.0.0.1:8080/health
      timeout_ms: 2000

  - kind: stdout_stderr
    stdout_stderr:
      command_id: regart-worker
      command: ["/usr/bin/regart-worker", "--serve"]

  - kind: otlp_logs
    otlp_logs:
      listener_id: local-otlp
      bind: 0.0.0.0:4317
```

## Поля
- `kind`: `file_tail | journald | systemd_unit | proc_probe | net_probe | stdout_stderr | otlp_logs`
- `file_tail.path`: абсолютный путь
- `journald.unit`: systemd unit matcher
- `systemd_unit.unit`: unit для state transitions
- `proc_probe.target_name`: стабильное имя процесса/цели
- `net_probe.target_name`: стабильное имя probe target
- `net_probe.url`: endpoint для reachability/latency
- `stdout_stderr.command_id`: стабильный id процесса
- `stdout_stderr.command`: команда запуска wrapper
- `otlp_logs.listener_id`: стабильный id ingress listener

## Deployment note
Где и как агент ставится в разных сетях/сегментах, описано в:
- `docs/source/agent_deployment_transport_v0_2.md`
- `docs/ops/agent_multisite_deploy.md`
