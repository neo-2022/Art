# Runbook: receiver_process_exited

## symptoms
- `observability_gap.receiver_process_exited`
- wrapped процесс завершился с non-zero

## checks
- exit code и stderr
- повторяемость сбоя при перезапуске

## mitigations
- исправить причину падения процесса
- применить retry policy запуска

## verification
- процесс стабильно работает
- ошибки exit не повторяются
