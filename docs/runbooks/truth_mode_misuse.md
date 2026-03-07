# Runbook: observability_gap.truth_mode_misuse

Событие: `observability_gap.truth_mode_misuse`  
Компонент: `console/truth-mode`

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- UI карточка в режиме `observed` отображается без `evidence_refs`.
- `predicted` элементы визуально неотличимы от фактических.
- Truth-mode suite падает на invariant checks.

## checks
1. Проверить payload `meta.truth_mode` и `meta.evidence_refs`.
2. Для `observed` подтвердить `evidence_refs_count > 0`.
3. Проверить `lineage_hash` и связность lineage chain.
4. Сверить UI badge mapping и schema constraints.

## mitigations
1. Заблокировать рендер спорного элемента как факта.
2. Исправить mapping truth-mode в producer/adapter.
3. Перезапустить `stage30-truth-modes-tests`.
4. Подтвердить PASS и отсутствие повторных misuse событий.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.truth_mode_misuse`.
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
