# Runbook: observability_gap.dna_canary_divergence

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- На canary узле результаты DNA отличаются от stable (или shadow/reference).
- Rollout gate блокирует расширение трафика.

## checks
1. Сверить build IDs canary/stable.
2. Проверить divergence sample (`dna_id`, `canonical_hash`, `payload_hash`).
3. Прогнать replay последнего окна событий на обоих build.

## mitigations
1. Немедленно остановить rollout.
2. Выполнить rollback до stable tag.
3. Открыть incident и приложить divergence fixture.
4. Разрешить повторный canary только после PASS stage29+stage34.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.dna_canary_divergence`.
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
