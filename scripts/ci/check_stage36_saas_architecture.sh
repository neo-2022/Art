#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md"
DOC="docs/source/saas_readiness_v0_2.md"
RUNBOOK_ISO="docs/runbooks/saas_tenant_isolation_failed.md"
RUNBOOK_PRIV="docs/runbooks/evidence_privacy_violation.md"
MATRIX="docs/source/saas_tenant_isolation_matrix_v0_2.json"
PARITY="docs/source/saas_console_api_parity_v0_2.json"
TENANT_SCHEMA="docs/contracts/v2/schemas/tenant_context_v2.json"
QUOTA_SCHEMA="docs/contracts/v2/schemas/saas_quota_retention_policy_v2.json"
AUDIT_SCHEMA="docs/contracts/v2/schemas/evidence_access_audit_record_v2.json"

for file in "$CHECKLIST" "$DOC" "$RUNBOOK_ISO" "$RUNBOOK_PRIV" "$MATRIX" "$PARITY" "$TENANT_SCHEMA" "$QUOTA_SCHEMA" "$AUDIT_SCHEMA"; do
  test -s "$file"
done

grep -q "tenant isolation proof suite" "$CHECKLIST"
grep -q "negative cross-tenant" "$DOC"
grep -q "observability_gap.saas_tenant_isolation_failed" docs/governance/observability_gap_registry.md

bash scripts/tests/stage36_tenant_contract_with_artifacts.sh
bash scripts/tests/stage36_architecture_validation_with_artifacts.sh
bash scripts/tests/stage36_console_parity_with_artifacts.sh
bash scripts/tests/stage36_privacy_workflow_with_artifacts.sh
bash scripts/tests/stage36_evidence_audit_trail_with_artifacts.sh
bash scripts/tests/stage36_observability_registry_with_artifacts.sh
bash scripts/tests/stage36_tenant_isolation_proof_with_artifacts.sh
bash scripts/tests/stage36_quota_burst_with_artifacts.sh
bash scripts/tests/stage36_retention_soak_with_artifacts.sh

for artifact in \
  docs/governance/evidence/stage36_step1_tenant_contract_report.json \
  docs/governance/evidence/stage36_step2_architecture_report.md \
  docs/governance/evidence/stage36_step3_console_parity_report.json \
  docs/governance/evidence/stage36_step4_privacy_workflow_report.md \
  docs/governance/evidence/stage36_step5_evidence_audit_trail_report.json \
  docs/governance/evidence/stage36_step6_registry_runbook_diff.log \
  docs/governance/evidence/stage36_step7_tenant_isolation_proof_report.json \
  docs/governance/evidence/stage36_step8_quota_burst_report.json \
  docs/governance/evidence/stage36_step9_retention_soak_report.json; do
  test -s "$artifact"
done

echo "stage36 saas architecture gate: OK"
