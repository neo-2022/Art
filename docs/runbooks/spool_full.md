# Runbook: spool_full

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

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
