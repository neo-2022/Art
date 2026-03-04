# REGART Art bridge runbook

## Overflow policies
- `never_drop_unacked`: reject new + `observability_gap.outbox_full/spool_full`
- `drop_oldest_when_full`: drop oldest + `data_quality.lossy_*` + incident `lossy_mode_active`

## Actions-only
Управление сервисами только через `POST /api/v1/actions/execute`.

## HTTPS-only
UI Proxy <-> Art Core по HTTPS, для dev допускается self-signed.
