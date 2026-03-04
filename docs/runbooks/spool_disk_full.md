# Runbook: spool_disk_full

## symptoms
- `observability_gap.spool_disk_full`
- ошибки записи в spool на агенте

## checks
- свободное место на spool пути
- рост очереди и retry/backoff

## mitigations
- освободить место на диске
- удалить временные/ротационные файлы по политике
- при необходимости переключить spool path на резервный том

## rollback
- вернуть исходный spool path после восстановления ёмкости

## verification
- запись в spool снова успешна
- flush в Core восстановлен

## escalation
- если нет прогресса 10 минут, эскалировать SEV1
