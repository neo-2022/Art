# Runbook: spool_disk_full

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

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
