# Runbook: spool_full

## symptoms
- `observability_gap.spool_full` в журнале
- рост backlog и остановка receiver ingest

## checks
- проверить `capacity_bytes/used_bytes/backlog_count`
- проверить доступность Core ingest

## mitigations
- восстановить доставку в Core
- временно снизить входной поток
- при согласовании увеличить capacity spool

## rollback
- вернуть baseline лимиты после стабилизации

## verification
- backlog снижается
- новых событий `spool_full` нет

## escalation
- если состояние > 15 минут, эскалировать On-call SEV1
