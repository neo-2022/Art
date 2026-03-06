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
- [x] 1. Сделать: contract model `org/project/env` с tenant isolation rules.
  - [x] Проверка (pass/fail): tenant contract tests PASS.
  - [x] Артефакт результата: contract tests report.
- [x] 2. Сделать: quotas/retention/compliance boundaries в control-plane/data-plane.
  - [x] Проверка (pass/fail): architecture validation tests PASS.
  - [x] Артефакт результата: architecture doc + validation log.
- [x] 3. Сделать: self-hosted/SaaS parity для Console API behavior.
  - [x] Проверка (pass/fail): compatibility suite PASS.
  - [x] Артефакт результата: compatibility report.
- [x] 4. Сделать: privacy workflows для evidence (retention, anonymization/remove by request).
  - [x] Проверка (pass/fail): compliance тест подтверждает SLA: `30/90/365+ days`, авто-анонимизацию PII при long-term retention и `request remediation <=72h`.
  - [x] Артефакт результата: compliance workflow report.
- [x] 5. Сделать: audit trail каждого доступа к evidence в SaaS mode.
  - [x] Проверка (pass/fail): audit logs содержат `evidence_id`, `actor_role`, `access_scope`, `decision`, `trace_id`.
  - [x] Артефакт результата: audit sample log + policy report.
- [x] 6. Сделать: observability-gap контроль нарушений tenant isolation и evidence privacy.
  - [x] События: `observability_gap.saas_tenant_isolation_failed`, `observability_gap.evidence_privacy_violation`.
  - [x] evidence_min:
    - `saas_tenant_isolation_failed`: `tenant_id`, `resource`, `policy_id`, `error`, `trace_id`.
    - `evidence_privacy_violation`: `evidence_id`, `actor_role`, `required_scope`, `redaction_policy_id`, `trace_id`.
  - [x] action_ref: `docs/runbooks/saas_tenant_isolation_failed.md`, `docs/runbooks/evidence_privacy_violation.md`.
  - [x] Проверка (pass/fail): registry записи + runbook файлы.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 7. Сделать: ввести tenant isolation proof suite с обязательными негативными cross-tenant тестами.
  - [x] Проверка (pass/fail): proof suite PASS и покрывает deny + audit trail assertions.
  - [x] Артефакт результата: isolation proof report.

## Документация (RU)
- [x] docs/source/saas_readiness_v0_2.md
- [x] docs/runbooks/saas_tenant_isolation_failed.md
- [x] docs/runbooks/evidence_privacy_violation.md
- [x] docs/source/risk_register_v0_2.md

## Тестирование
- [x] unit: tenant/policy validators.
- [x] integration: control-plane/data-plane boundaries.
- [x] e2e: parity сценарии self-hosted/SaaS.
- [x] chaos: cross-tenant access attempt.
- [x] integration: tenant isolation proof suite (deny matrix + audit assertions).
- [x] compliance: anonymization/removal request workflow.
- [x] load: quota enforcement under burst.
- [x] soak: retention window lifecycle.

## CI gate
- [x] `stage36-saas-architecture-gate`

## DoD
- [x] Tenant isolation формально определён и подтверждён тестами.
- [x] Tenant isolation proof suite фиксирует отрицательные cross-tenant сценарии.
- [x] Console parity для self-hosted/SaaS подтверждён.
- [x] observability-gap событие этапа 36 зарегистрировано и имеет runbook.
- [x] Риск R9 из risk register закрыт privacy workflows и audit контролями.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_37 запрещён до полного закрытия CHECKLIST_36.
- Артефакты закрытия: architecture/test reports + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
