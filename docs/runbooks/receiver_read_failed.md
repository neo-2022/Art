# Runbook: receiver_read_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- `observability_gap.receiver_read_failed`
- intermittent read ошибки источника

## checks
- доступность источника (файл, journald, process pipe)
- системные ошибки I/O

## mitigations
- восстановить источник/канал чтения
- проверить лимиты файловых дескрипторов
- перезапустить проблемный receiver

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- read ошибки прекратились
- source_seq монотонно растёт

## escalation
- Эскалировать on-call и Incident Commander, если mitigation не восстановила сервис в рамках SLA severity.
- При SEV1+ или повторном срабатывании приложить evidence refs и связанный incident/postmortem trail.

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
