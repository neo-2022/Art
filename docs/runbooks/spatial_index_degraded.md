# Runbook: observability_gap.spatial_index_degraded

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Picking latency превышает threshold.
- 3D selection sync нестабилен.

## checks
1. Проверить `layout_id/node_count/picking_ms/threshold_ms`.
2. Запустить stage35 spatial perf tests.
3. Проверить целостность index/chunks.

## mitigations
1. Перестроить spatial index.
2. Оптимизировать LOD thresholds.
3. Повторить perf tests.

## rollback
- Переключить на предыдущую стабильную версию spatial index algorithm.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.spatial_index_degraded`.
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
