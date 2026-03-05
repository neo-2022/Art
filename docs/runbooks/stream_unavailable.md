# Runbook: stream_unavailable

## symptoms
- `/api/v1/stream` отвечает `503`.
- В snapshot появляются события `observability_gap.stream_unavailable`.

## checks
- Проверить health Core (`/health`).
- Проверить ошибки Core в systemd/journal.
- Проверить storage-состояние и лимиты очередей.

## mitigations
- Перезапустить Core service.
- Устранить внутреннюю причину (storage/runtime error).
- Временно снизить поток ingest до стабилизации.

## rollback
- Вернуть последнюю стабильную конфигурацию Core.
- Откатить последние изменения, затрагивающие stream.

## verification
- `/api/v1/stream` снова отдаёт `200` и `text/event-stream`.
- Новые `observability_gap.stream_unavailable` не появляются.
- Клиенты получают SSE без 503.

## escalation
- Эскалировать SRE on-call при повторе >3 раз за 10 минут.
