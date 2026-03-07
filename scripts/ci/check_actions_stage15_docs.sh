#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/core/actions.md"
  "docs/core/audit.md"
  "docs/security/rbac.md"
  "docs/security/pii_secret_filter.md"
  "docs/security/mcp_modes_runtime.md"
  "docs/runbooks/access_denied.md"
  "docs/source/trust_boundary_hardening_v0_2.md"
  "docs/runbooks/trust_boundary_violation.md"
)

for f in "${required_files[@]}"; do
  test -f "$f"
done

grep -q "viewer" docs/security/rbac.md
grep -q "operator" docs/security/rbac.md
grep -q "admin" docs/security/rbac.md

grep -q "read_only" docs/security/mcp_modes_runtime.md
grep -q "limited_actions" docs/security/mcp_modes_runtime.md
grep -q "full_admin" docs/security/mcp_modes_runtime.md

grep -q "client_ip" docs/core/audit.md
grep -q "user_agent" docs/core/audit.md
grep -q "append-only" docs/core/audit.md
grep -q "prev_hash" docs/core/audit.md
grep -q "entry_hash" docs/core/audit.md
grep -q "/api/v1/audit/verify" docs/core/audit.md

grep -q "pre-write" docs/security/pii_secret_filter.md
grep -q "redaction" docs/security/pii_secret_filter.md
grep -q "trusted" docs/source/trust_boundary_hardening_v0_2.md
grep -q "fail-closed" docs/source/trust_boundary_hardening_v0_2.md
grep -q "observability_gap.trust_boundary_violation" docs/governance/observability_gap_registry.md

grep -q "mitigations" docs/runbooks/access_denied.md
grep -q "verification" docs/runbooks/access_denied.md
grep -q "mitigations" docs/runbooks/trust_boundary_violation.md
grep -q "verification" docs/runbooks/trust_boundary_violation.md
echo "stage15 actions docs gate: OK"
