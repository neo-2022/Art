# CHECKLIST 36 — SaaS Readiness Architecture
Файл: CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение tenant isolation, quotas/retention/compliance contracts
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Зафиксировать и проверить SaaS-ready архитектуру: tenant isolation, control-plane/data-plane, policy parity с self-hosted.

## Границы
- Включено: tenant model contracts, quotas, retention, compliance export boundaries.
- Включено: compatibility contracts между self-hosted и SaaS.
- Исключено: production биллинг engine.

## Зависимости
- CHECKLIST 01 (governance)
- CHECKLIST 25 (compliance)
- CHECKLIST 35 (spatial readiness закрыт)

## Шаги (строго линейно)
- [ ] 1. Сделать: contract model `org/project/env` с tenant isolation rules.
  - [ ] Проверка (pass/fail): tenant contract tests PASS.
  - [ ] Артефакт результата: contract tests report.
- [ ] 2. Сделать: quotas/retention/compliance boundaries в control-plane/data-plane.
  - [ ] Проверка (pass/fail): architecture validation tests PASS.
  - [ ] Артефакт результата: architecture doc + validation log.
- [ ] 3. Сделать: self-hosted/SaaS parity для Console API behavior.
  - [ ] Проверка (pass/fail): compatibility suite PASS.
  - [ ] Артефакт результата: compatibility report.
- [ ] 4. Сделать: privacy workflows для evidence (retention, anonymization/remove by request).
  - [ ] Проверка (pass/fail): compliance тест подтверждает SLA: `30/90/365+ days`, авто-анонимизацию PII при long-term retention и `request remediation <=72h`.
  - [ ] Артефакт результата: compliance workflow report.
- [ ] 5. Сделать: audit trail каждого доступа к evidence в SaaS mode.
  - [ ] Проверка (pass/fail): audit logs содержат `evidence_id`, `actor_role`, `access_scope`, `decision`, `trace_id`.
  - [ ] Артефакт результата: audit sample log + policy report.
- [ ] 6. Сделать: observability-gap контроль нарушений tenant isolation и evidence privacy.
  - [ ] События: `observability_gap.saas_tenant_isolation_failed`, `observability_gap.evidence_privacy_violation`.
  - [ ] evidence_min:
    - `saas_tenant_isolation_failed`: `tenant_id`, `resource`, `policy_id`, `error`, `trace_id`.
    - `evidence_privacy_violation`: `evidence_id`, `actor_role`, `required_scope`, `redaction_policy_id`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/saas_tenant_isolation_failed.md`, `docs/runbooks/evidence_privacy_violation.md`.
  - [ ] Проверка (pass/fail): registry записи + runbook файлы.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 7. Сделать: ввести tenant isolation proof suite с обязательными негативными cross-tenant тестами.
  - [ ] Проверка (pass/fail): proof suite PASS и покрывает deny + audit trail assertions.
  - [ ] Артефакт результата: isolation proof report.

## Документация (RU)
- [ ] docs/source/saas_readiness_v0_2.md
- [ ] docs/runbooks/saas_tenant_isolation_failed.md
- [ ] docs/runbooks/evidence_privacy_violation.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] unit: tenant/policy validators.
- [ ] integration: control-plane/data-plane boundaries.
- [ ] e2e: parity сценарии self-hosted/SaaS.
- [ ] chaos: cross-tenant access attempt.
- [ ] integration: tenant isolation proof suite (deny matrix + audit assertions).
- [ ] compliance: anonymization/removal request workflow.
- [ ] load: quota enforcement under burst.
- [ ] soak: retention window lifecycle.

## CI gate
- [ ] `stage36-saas-architecture-gate`

## DoD
- [ ] Tenant isolation формально определён и подтверждён тестами.
- [ ] Tenant isolation proof suite фиксирует отрицательные cross-tenant сценарии.
- [ ] Console parity для self-hosted/SaaS подтверждён.
- [ ] observability-gap событие этапа 36 зарегистрировано и имеет runbook.
- [ ] Риск R9 из risk register закрыт privacy workflows и audit контролями.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_37 запрещён до полного закрытия CHECKLIST_36.
- Артефакты закрытия: architecture/test reports + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
