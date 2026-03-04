# Runbook: receiver_paused_spool_full

## symptoms
- receiver перестал читать источник
- `observability_gap.receiver_paused_spool_full`

## checks
- активная spool policy
- текущие `used_bytes/backlog_count`

## mitigations
- разгрузить spool через восстановление канала в Core
- уменьшить входной поток из источника

## verification
- receiver resume подтверждён
- source_seq снова растёт
