# Runbook: observability_gap.dna_determinism_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Один и тот же replay даёт разные `dna_id`/cluster boundaries.
- Canary validator расходится с primary pipeline.

## checks
1. Проверить `dna_schema_version` и последний deploy SHA.
2. Сравнить canonical payload hashes для одинаковых raw events.
3. Прогнать:
   - `bash scripts/ci/run_stage29_dna_tests.sh`
   - `bash scripts/ci/run_stage29_dna_property_million.sh`
4. Проверить, нет ли drift между моделью и кодом (`docs/contracts/v2/dna_model/*`).

## mitigations
1. Остановить rollout DNA Core.
2. Переключить feature flag `dna_core_v2_enabled=0` (fallback raw-events mode).
3. Сгенерировать reproducible fixture и добавить regression тест.
4. Выпустить фикс, повторно пройти stage29+stage34 gates.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.dna_determinism_violation`.
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
