#!/usr/bin/env bash
set -euo pipefail

test -s "docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md"
test -s "docs/source/secure_actions_protocol_v2.md"
test -s "docs/runbooks/action_preflight_missing.md"

grep -q "stage33-secure-actions-tests" docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
grep -q "observability_gap.action_preflight_missing" docs/governance/observability_gap_registry.md

# Runtime integration suite (preflight/policy/RBAC/actions)
cargo test -p art-core rbac_matrix_enforced_for_actions_and_audit
cargo test -p art-core mcp_modes_enforced_for_actions
cargo test -p art-core access_denied_event_emitted_for_forbidden_action
cargo test -p art-core actions_secret_redaction_happens_pre_write

echo "stage33 secure actions gate: OK"
