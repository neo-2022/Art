# Runbook: stream_lag

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- В snapshot появляются `observability_gap.stream_lag`.
- Lag превышает порог 5000 мс.

## checks
- Проверить backlog и ingest скорость.
- Проверить доступность storage и I/O задержки.
- Проверить CPU/RAM Core.

## mitigations
- Снизить ingest rate.
- Увеличить ресурсы Core (CPU/RAM/IOPS).
- Временно ограничить число подписчиков.

## rollback
- Откатить последние изменения stream/pipeline.
- Вернуть стабильные лимиты и конфигурацию.

## verification
- `stream_lag_ms` p95 <= 2000 мс на smoke/load.
- Новые `observability_gap.stream_lag` не генерируются в стабильном режиме.
- Подписчики получают поток без накопления задержки.

## escalation
- Эскалировать SRE on-call при lag >5000 мс дольше 5 минут.

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
