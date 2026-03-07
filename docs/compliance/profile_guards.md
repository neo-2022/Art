# Profile guards

Проверки:
- retention: значения retention по событиям, инцидентам и аудиту соответствуют активному профилю;
- export: режим экспорта и target whitelist соответствуют активному профилю;
- egress: разрешённые outbound destinations и default action соответствуют активному профилю;
- residency: хранилища для events/incidents/audit/attachments допустимы для активного профиля;
- updates/packs: источник обновлений, тип bundles и signing policy соответствуют активному профилю.

Правило: fail closed (блокировать запуск/применение при нарушении).

Точка применения guardrails:
- startup Core;
- `POST /api/v1/profile/apply`.

Если любая проверка не пройдена:
- Core не стартует или reject apply-config;
- профиль не меняется частично;
- ingest не запускается;
- старый валидный профиль остаётся единственным активным состоянием.

Применение профиля в runtime:
- `POST /api/v1/profile/apply`
- При нарушении guardrails: HTTP 400 и профиль не применяется (fail closed).

## observability_gap.profile_violation
- Событие обязательно попадает в snapshot/stream.
- evidence_min: violated_rule, profile_id, parameter, current_values.
- incident_rule: `profile_guardrail_breach`
- action_ref: `docs/runbooks/profile_violation.md`.
- Реестр: `docs/governance/observability_gap_registry.md`.
