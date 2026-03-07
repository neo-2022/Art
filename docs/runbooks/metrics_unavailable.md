# Runbook: metrics_unavailable

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- В snapshot/stream/логах наблюдается сигнал `metrics_unavailable` или эквивалентный сбой.
- Нарушение влияет на связанный компонент и требует triage в рамках текущего SLA.

## checks
- Проверить последнее событие, `trace_id`/`request_id`/`audit_id`, affected component и time window.
- Проверить связанный конфиг, последний релиз, feature flags и состояние зависимостей.
- Исключить смежные причины: transport, storage, auth, network, data drift.

## mitigations
1. Проверить доступность `/metrics` и состояние Core.
2. Проверить сетевой путь/балансировщик.
3. Повторить scrape после восстановления.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- `/metrics` отвечает HTTP 200;
- новых `observability_gap.metrics_unavailable` нет.

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
