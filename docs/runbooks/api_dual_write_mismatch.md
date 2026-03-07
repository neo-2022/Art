# Runbook: observability_gap.api_dual_write_mismatch

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Расхождение данных между v1/v2 путями.
- Верификатор dual-write фиксирует matured mismatch (после окна допустимой задержки доставки).

## checks
1. Сверить v1/v2 payload для одного trace_id.
2. Проверить, что trace_id вышел из `delivery_lag_grace_window` (default `10s`; pending записи не считаются mismatch).
3. Проверить миграцию `events_v2/dna_clusters/evidence_blocks`.
4. Прогнать stage29 suite.

## mitigations
1. Остановить rollout API v2 изменений.
2. Исправить mapper/adapters и миграцию.
3. Повторить dual-write verification до `normalized mismatch rate = 0` на matured наборе.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.api_dual_write_mismatch`.
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
