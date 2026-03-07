# Runbook: observability_gap.console_linux_readiness_failed

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Linux readiness suite Console не проходит.
- Rollout заблокирован alert gate.

## checks
1. Проверить `suite/scenario/error/build_id`.
2. Запустить `scripts/tests/console_linux_prod_readiness.sh` локально.
3. Сверить состояние Core snapshot/stream.

## mitigations
1. Исправить failing scenario.
2. Повторить readiness suite на canary.
3. Подтвердить отсутствие regression alert.

## rollback
- Вернуться на previous stable tag и повторить readiness verification.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.console_linux_readiness_failed`.
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
