# REGART Art bridge runbook

## Overflow policies
- `never_drop_unacked` (default): receivers pause when the spool is full; new events are rejected while `observability_gap.outbox_full` and `observability_gap.spool_full` fire (metadata includes `artifact=spool`, `retry_count=0`). Metrics: `outbox_rejected_total`, `spool_rejected_total`.
- `drop_oldest_when_full`: the oldest buffered events are dropped to keep the queue bounded, `data_quality.lossy_outbox_drop` / `data_quality.lossy_spool_drop` emit loss metrics, `lossy_mode_active` incident is created, and counters `outbox_dropped_total` / `spool_dropped_total` increment for monitoring.

## Actions-only
- Управление сервисами происходит исключительно через `POST /api/v1/actions/execute` (Art Actions API). UI Proxy не вызывает `systemctl`, `tmux`, `bash` или прочие управленческие команды напрямую — все операции идут через безопасный actions-сервис.
- При неудаче любое action-вызов пишет `observability_gap.actions.failure`, включая название action и параметры, чтобы Debugger отображал что произошло и куда смотреть (например `service_control` не вернул `ok`).

## HTTPS-only
- Канал UI Proxy ↔ Art Core работает только по HTTPS (`ART_INGEST_URL`, `ART_STREAM_URL`, `ART_ACTIONS_URL` начинаются с `https://`).
- HTTP-соединения блокируются в рантайме (`500`, detail: `... must use https://`), чтобы transport-контур UI Proxy↔Art Core не деградировал до insecure режима.
- В dev допускается self-signed сертификат через `ART_TLS_VERIFY=0`.

## Audit append-only
- Аудит хранится в таблице `spool_audit` и является append-only.
- Любые попытки `UPDATE`/`DELETE` блокируются sqlite-триггерами.
- При попытке изменить/удалить запись логируется `observability_gap.audit_tampering`.
