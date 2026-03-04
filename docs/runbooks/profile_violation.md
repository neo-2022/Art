# Runbook: profile_violation

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
