#!/usr/bin/env bash
set -euo pipefail

required=(
  docs/governance/roles_raci.md
  docs/governance/oncall.md
  docs/governance/severity.md
  docs/governance/incident_process.md
  docs/governance/observability_gap_registry.md
  docs/governance/runbook_policy.md
  docs/governance/slo_sli.md
  docs/governance/error_budget_policy.md
  docs/governance/postmortem_policy.md
  docs/governance/postmortem_template.md
  docs/governance/change_policy.md
  docs/governance/repo_protection_evidence.md
  docs/governance/release_process.md
  docs/governance/mcp_modes.md
  docs/governance/audit_policy.md
  docs/governance/vulnerability_process.md
  docs/governance/evidence_policy.md
  docs/governance/tabletop_exercise.md
  docs/governance/evidence/branch_protection_main.png
  scripts/ci/check_governance_stage01.sh
  .github/CODEOWNERS
  .github/pull_request_template.md
  .github/ISSUE_TEMPLATE/incident.yml
  .github/ISSUE_TEMPLATE/bug.yml
  SECURITY.md
)

for f in "${required[@]}"; do
  test -s "$f"
done

grep -q "observability_gap escalation" docs/governance/incident_process.md
grep -q "SLO breach mapping" docs/governance/slo_sli.md
grep -q "action_ref" docs/governance/slo_sli.md
grep -q "incident_rule" docs/governance/slo_sli.md
for key in event_name owner_component owner_role incident_rule example action_ref; do
  grep -q "$key" docs/governance/observability_gap_registry.md
done
grep -Eq "immutable|неизменяемый" docs/governance/audit_policy.md
for key in timestamp actor action target result evidence_ref; do
  grep -q "$key" docs/governance/audit_policy.md
done
grep -Eq "1 year|не менее 1 года" docs/governance/audit_policy.md

echo "governance stage01 gate: OK"
