# Runbook: observability_gap.v2_migration_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Migration этап v2 завершился ошибкой.
- API v2 отвечает нестабильно после deploy.

## checks
1. Проверить `migration_id/db_path/stage/error`.
2. Сверить шаги с `docs/contracts/v2/migrations_v2.md`.
3. Подтвердить состояние v1 endpoints.

## mitigations
1. Выполнить rollback sequence из migration doc.
2. Восстановить dual-read безопасный режим.
3. Повторить canary verification.

## rollback
- Откат на предыдущий stable tag с v1-only traffic.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.v2_migration_failed`.
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
