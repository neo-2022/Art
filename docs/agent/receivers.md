# Art Agent Receivers v1

## `receiver_kind` (фиксированный enum)
- `file_tail`
- `journald`
- `stdout_stderr`

## Контракт RawEvent от receivers
- `source_id` (string, уникален в рамках агента)
- `source_seq` (int >= 0, монотонный для данного `source_id`)
- `source_ts_ms` (int >= 0)
- `receiver_kind` (enum)
- `trace_id` (всегда присутствует)
- `retry_count` (int >= 0, всегда присутствует)

## Правило source_id
- `file_tail` -> `file:<abs_path>`
- `journald` -> `journald:<unit_or_matcher_id>`
- `stdout_stderr` -> `proc:<command_id>`

## Backpressure
- При `never_drop_unacked`: receiver pause + `observability_gap.receiver_paused_spool_full`.
- При `drop_oldest_when_full`: чтение продолжается + lossy события.
