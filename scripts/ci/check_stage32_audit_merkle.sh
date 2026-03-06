#!/usr/bin/env bash
set -euo pipefail

test -s "docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md"
test -s "docs/source/audit_merkle_verify.md"
test -s "docs/runbooks/audit_merkle_verify_failed.md"

grep -q "stage32-audit-merkle-tests" docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
grep -q "observability_gap.audit_merkle_verify_failed" docs/governance/observability_gap_registry.md

# Runtime integration suite (audit + merkle verify)
cargo test -p art-core audit_is_append_only_update_delete_forbidden
cargo test -p art-core audit_chain_verify_endpoint_is_ok_for_intact_entries
cargo test -p art-core audit_chain_verify_detects_tampering

echo "stage32 audit merkle gate: OK"
