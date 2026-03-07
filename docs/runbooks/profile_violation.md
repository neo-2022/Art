# Runbook: profile_violation

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- `observability_gap.profile_violation` в snapshot/stream
- `POST /api/v1/profile/apply` возвращает HTTP 400

## checks
- сверить `profile_id` и параметры профиля с `docs/compliance/profiles.md`
- проверить причину в поле `reason` события

## mitigations
- исправить конфиг профиля (`retention/export/egress/residency/updates_mode`)
- повторно применить профиль только после прохождения guardrails

## rollback
- вернуть последний валидный конфиг профиля

## verification
- повторный apply проходит с HTTP 200
- новых `observability_gap.profile_violation` нет

## escalation
- при повторных нарушениях эскалировать On-call (SEV1)

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
