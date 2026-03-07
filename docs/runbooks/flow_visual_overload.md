# Runbook: observability_gap.flow_visual_overload

Событие: `observability_gap.flow_visual_overload`  
Компонент: `console/flow`

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Flow Mode теряет интерактивность при штатной нагрузке.
- `p95_ms` превышает `budget_ms`.
- Auto-downgrade не активировался или активировался с опозданием.

## checks
1. Проверить payload события: `layout_id`, `node_count`, `p95_ms`, `budget_ms`, `downgrade_applied`.
2. Проверить текущий режим `flow complexity` и feature-flag advanced mode.
3. Подтвердить, что watchdog policy применена корректно.
4. Сравнить метрики до и после деградации качества.

## mitigations
1. Включить принудительный read-only fallback для Flow Mode.
2. Уменьшить visual density и motion profile до safe baseline.
3. Повторно прогнать:
   - `stage35-flow-inspectability-tests`
   - `stage35-flow-snapshot-replay-tests`
   - `stage35-flow-perf-2d-gate`
4. Снять forced fallback только после PASS всех проверок.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.flow_visual_overload`.
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
