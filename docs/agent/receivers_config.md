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

  - kind: stdout_stderr
    stdout_stderr:
      command_id: regart-worker
      command: ["/usr/bin/regart-worker", "--serve"]
```

## Поля
- `kind`: `file_tail | journald | stdout_stderr`
- `file_tail.path`: абсолютный путь
- `journald.unit`: systemd unit matcher
- `stdout_stderr.command_id`: стабильный id процесса
- `stdout_stderr.command`: команда запуска wrapper
