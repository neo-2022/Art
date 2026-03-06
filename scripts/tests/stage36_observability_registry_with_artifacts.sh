#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step6_registry_runbook_diff.log"

mkdir -p "$OUT_DIR"

REG="docs/governance/observability_gap_registry.md"
RUN1="docs/runbooks/saas_tenant_isolation_failed.md"
RUN2="docs/runbooks/evidence_privacy_violation.md"

grep -q "^| observability_gap.saas_tenant_isolation_failed |" "$REG"
grep -q "^| observability_gap.evidence_privacy_violation |" "$REG"
grep -q "tenant_id, resource, policy_id, error, trace_id" "$REG"
grep -q "evidence_id, actor_role, required_scope, redaction_policy_id, trace_id" "$REG"

test -s "$RUN1"
test -s "$RUN2"

{
  echo "stage36 step6 registry/runbook: PASS"
  echo "registry=$REG"
  echo "runbook1=$RUN1"
  echo "runbook2=$RUN2"
} | tee "$LOG_FILE"
