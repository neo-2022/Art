# Runbook: otlp_rate_limited

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- рост 429/503/413 на OTLP endpoint
- событие `observability_gap.otlp_rate_limited` появляется в snapshot/stream

## checks
- проверить `limit_name`, `current_value`, `retry_after_ms`, `endpoint`, `trace_id` в событии
- сверить фактический поток с лимитами (`max_events_per_sec`, `burst`, `max_batch_events`, `max_size_bytes`)

## mitigations
- снизить входной поток OTLP с источника
- уменьшить размер batch/частоту отправки
- временно увеличить capacity receiver (если допустимо по профилю)

## rollback
- вернуть штатные лимиты после стабилизации потока
- подтвердить отсутствие новых событий `observability_gap.otlp_rate_limited`

## verification
- форсировать короткий тестовый burst и проверить ожидаемый backpressure статус
- убедиться, что `retry_after_ms` возвращается в ответе
- убедиться, что событие видно в snapshot/stream с полным evidence

## escalation
- если срабатывание длится >15 минут, эскалировать в on-call SEV2

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
