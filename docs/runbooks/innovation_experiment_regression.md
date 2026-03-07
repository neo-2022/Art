# Runbook: observability_gap.innovation_experiment_regression

Событие: `observability_gap.innovation_experiment_regression`
Компонент: `console/innovation`
Критичность по умолчанию: `SEV1`

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- KPI/ SLO для экспериментальных треков (`RTP`, `LRC`, `NRAC`) вышли за policy threshold.
- Канареечный rollout показывает деградацию относительно baseline.
- Gate-отчёт фиксирует `actual` хуже `baseline` по критичным метрикам.

## checks
1. Убедиться, что событие содержит полный `evidence_min`:
   - `experiment`, `metric`, `baseline`, `actual`, `threshold`, `trace_id`.
2. Проверить текущие значения feature flags:
   - `rtp_enabled`, `lrc_enabled`, `nrac_enabled`.
3. Сравнить canary и stable профили:
   - есть ли расхождение только на canary или в обоих контурах.
4. Подтвердить воспроизводимость регрессии:
   - повторить KPI suite на том же build/profile.

## mitigations
1. Немедленно выключить проблемный экспериментальный флаг (`auto-disable` или ручное отключение).
2. Остановить расширение rollout и вернуть canary к stable build.
3. Зафиксировать инцидент и создать remediation-задачу с root cause.
4. Повторно прогнать KPI suite:
   - PASS только при возврате в policy bounds.
5. Разрешить повторный rollout только после:
   - исправления,
   - повторного PASS KPI regression gate,
   - обновления артефактов в risk register/checklist.

## rollback
- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.
- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.innovation_experiment_regression`.
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
