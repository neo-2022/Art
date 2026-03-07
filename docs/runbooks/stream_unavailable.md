# Runbook: stream_unavailable

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

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

## evidence
- Сохранить event payload, `trace_id`/`request_id`/`audit_id`, affected component, version/build, config diff и relevant log excerpts.
- Для UI/runtime проблем приложить screenshot/video reproduction и browser/runtime context.
- Для release/config проблем приложить commit/tag/PR и rollback decision.

## owner
- Основной владелец: дежурный инженер и компонент-владелец по RACI/реестру событий.
- Ответственный за эскалацию: Incident Commander для SEV1+ или затяжного инцидента.

## degraded mode
- Если полное восстановление недоступно, включить документированный degraded/read-only mode для затронутой поверхности.
- Зафиксировать scope деградации, срок действия и условие выхода из degraded mode.
