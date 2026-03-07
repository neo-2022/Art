# Runbook: observability_gap.audit_merkle_verify_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Verify endpoint возвращает failed.
- UI audit chain показывает разрыв.

## checks
1. Проверить `audit_id/proof_hash/step/error`.
2. Запустить stage32 verify tests.
3. Проверить источник tampering.

## mitigations
1. Восстановить корректную chain последовательность.
2. Перестроить proof refs для затронутых записей.
3. Повторить verify tests.

## rollback
- Отключить автоматический verify UI для затронутого диапазона до восстановления целостности.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.audit_merkle_verify_failed`.
- Snapshot/stream/метрики подтверждают восстановление без новых regressions.
- Смежные hostile paths не деградировали после remediation.

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
