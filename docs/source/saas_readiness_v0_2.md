# SaaS Readiness v0.2

Последняя актуализация: 2026-03-06

## Цель
Формализовать SaaS-ready архитектуру без расхождения API поведения с self-hosted.

## Модель
- tenant hierarchy: org/project/env
- control-plane/data-plane boundaries
- quotas/retention/compliance export
- tenant isolation contract: `docs/contracts/v2/schemas/tenant_context_v2.json`
- quotas/retention contract: `docs/contracts/v2/schemas/saas_quota_retention_policy_v2.json`
- evidence access audit contract: `docs/contracts/v2/schemas/evidence_access_audit_record_v2.json`

## Tenant Isolation Rules (MUST)
- Любой cross-tenant доступ: `deny`.
- Разделение выполняется по `org_id/project_id/env_id` + `tenant_id`.
- Для каждого deny/allow по evidence обязательно формируется audit record:
  `evidence_id`, `actor_role`, `access_scope`, `decision`, `trace_id`, `ts_ms`.
- Негативная матрица cross-tenant сценариев: `docs/source/saas_tenant_isolation_matrix_v0_2.json`.

## Control-Plane / Data-Plane Boundaries
- Control-plane: policies, quotas, retention config, compliance export profiles.
- Data-plane: ingest/snapshot/stream/actions/evidence access execution path.
- Policy-as-UI parity: Console показывает один и тот же policy outcome для self-hosted и SaaS.
- Console API parity contract: `docs/source/saas_console_api_parity_v0_2.json`.

## Инварианты
- Tenant isolation обязательна.
- API parity для Console обязательна.
- Нарушения isolation логируются как observability_gap.
- Каждый доступ к evidence имеет audit trail.
- Retention/anonymization workflow обязателен для privacy compliance.

## Проверка
- unit tenant policy
- integration isolation and quotas
- integration tenant isolation proof suite (negative cross-tenant matrix + audit assertions)
- e2e parity scenarios
- compliance retention/anonymization scenarios
- gate: `bash scripts/ci/check_stage36_saas_architecture.sh`

## Evidence SLA (фикс)
- оперативные данные evidence: 30 дней.
- evidence инцидентов: 90 дней.
- audit/compliance evidence: 365+ дней.
- при переходе в long-term retention PII анонимизируется автоматически.
- request-driven anonymization/removal: не позднее 72 часов.

## Source of truth
- docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md
- docs/contracts/v2/schemas/tenant_context_v2.json
- docs/contracts/v2/schemas/saas_quota_retention_policy_v2.json
- docs/contracts/v2/schemas/evidence_access_audit_record_v2.json
- docs/governance/observability_gap_registry.md
- docs/runbooks/saas_tenant_isolation_failed.md
- docs/runbooks/evidence_privacy_violation.md
