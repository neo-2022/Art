#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
RUST_LOG="$OUT_DIR/stage36_step7_tenant_isolation_rust_test.log"
PROOF_JSON="$OUT_DIR/stage36_step7_tenant_isolation_proof_report.json"

mkdir -p "$OUT_DIR"

cargo test -p art-core v2_evidence_access_scope_enforcement_tests -- --nocapture | tee "$RUST_LOG"

python3 - <<'PY'
import json
from pathlib import Path

matrix = json.loads(Path("docs/source/saas_tenant_isolation_matrix_v0_2.json").read_text(encoding="utf-8"))
cases = matrix.get("negative_cross_tenant_matrix", [])
if not cases:
    raise SystemExit("negative cross-tenant matrix is empty")

if any(c.get("expected_decision") != "deny" for c in cases):
    raise SystemExit("matrix contains non-deny expectations")

report = {
    "status": "PASS",
    "proof_suite": "v2_evidence_access_scope_enforcement_tests + negative matrix validation",
    "negative_case_count": len(cases),
    "audit_assertion": "deny decision is required for cross-tenant access"
}
Path("docs/governance/evidence/stage36_step7_tenant_isolation_proof_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("stage36 step7 tenant isolation proof suite: PASS")
PY

test -s "$PROOF_JSON"
