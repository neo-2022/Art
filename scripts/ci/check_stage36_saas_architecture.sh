#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md"
DOC="docs/source/saas_readiness_v0_2.md"
RUNBOOK_ISO="docs/runbooks/saas_tenant_isolation_failed.md"
RUNBOOK_PRIV="docs/runbooks/evidence_privacy_violation.md"

for file in "$CHECKLIST" "$DOC" "$RUNBOOK_ISO" "$RUNBOOK_PRIV"; do
  test -s "$file"
done

grep -q "tenant isolation proof suite" "$CHECKLIST"
grep -q "negative cross-tenant" "$DOC"
grep -q "observability_gap.saas_tenant_isolation_failed" docs/governance/observability_gap_registry.md

echo "stage36 saas architecture gate: OK"
