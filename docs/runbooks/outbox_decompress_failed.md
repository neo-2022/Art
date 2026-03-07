# Runbook: outbox_decompress_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- В snapshot/stream/логах наблюдается сигнал `outbox_decompress_failed` или эквивалентный сбой.
- Нарушение влияет на связанный компонент и требует triage в рамках текущего SLA.

## checks
- Проверить последнее событие, `trace_id`/`request_id`/`audit_id`, affected component и time window.
- Проверить связанный конфиг, последний релиз, feature flags и состояние зависимостей.
- Исключить смежные причины: transport, storage, auth, network, data drift.

## mitigations
1. Проверить целостность outbox payload (битые gzip записи).
2. Проверить версию кодека и совместимость формата хранения.
3. Перевести проблемные записи в DLQ/карантин и повторить flush.
4. Проверить транспорт до ingest после восстановления.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
1. В snapshot/stream появилось событие `observability_gap.outbox_decompress_failed`.
2. В событии есть `trace_id` и evidence: `dedup_key`, `error`, `endpoint`.
3. После исправления новые события ошибки распаковки не появляются.

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
