# Runbook: receiver_process_spawn_failed

## symptoms
- `observability_gap.receiver_process_spawn_failed`
- receiver `stdout_stderr` не запускает процесс

## checks
- путь к бинарю и права на запуск
- валидность `command_id` и аргументов

## mitigations
- исправить конфиг команды
- восстановить бинарь/окружение и повторить запуск

## verification
- процесс успешно стартует
- поступают события stdout/stderr
