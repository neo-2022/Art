# Receiver chaos matrix

Команда runtime smoke:

```bash
bash scripts/tests/agent_receivers_chaos_runtime.sh
```

Матрица сценариев:

1. `file_tail` permission denied:
   - запрос parse возвращает `403`;
   - генерируется `observability_gap.receiver_permission_denied`.
2. `stdout_stderr` spawn failed:
   - запрос parse возвращает `400`;
   - генерируется `observability_gap.receiver_process_spawn_failed`.
3. unsupported receiver kind:
   - запрос parse возвращает `400`;
   - генерируется `observability_gap.receiver_read_failed`.
4. structured parse fail:
   - parse с невалидным JSON возвращает `200`;
   - генерируется `data_quality.receiver_parse_failed`.
5. multiline oversize:
   - вход > `max_event_bytes=65536`;
   - генерируется `data_quality.receiver_multiline_truncated`.
6. pre-write redaction:
   - секрет в source (`token=...`) маскируется до `***redacted***` в `payload.raw_line`.
