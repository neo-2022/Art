# Runbook: receiver_read_failed

## symptoms
- `observability_gap.receiver_read_failed`
- intermittent read ошибки источника

## checks
- доступность источника (файл, journald, process pipe)
- системные ошибки I/O

## mitigations
- восстановить источник/канал чтения
- проверить лимиты файловых дескрипторов
- перезапустить проблемный receiver

## verification
- read ошибки прекратились
- source_seq монотонно растёт
