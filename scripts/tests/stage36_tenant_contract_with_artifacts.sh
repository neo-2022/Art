#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step1_tenant_contract.log"
REPORT_JSON="$OUT_DIR/stage36_step1_tenant_contract_report.json"

mkdir -p "$OUT_DIR"

python3 - <<'PY' | tee "$LOG_FILE"
import json
from pathlib import Path

schema = Path("docs/contracts/v2/schemas/tenant_context_v2.json")
matrix = Path("docs/source/saas_tenant_isolation_matrix_v0_2.json")

s = json.loads(schema.read_text(encoding="utf-8"))
m = json.loads(matrix.read_text(encoding="utf-8"))

required = set(s["required"])
expected_required = {"org_id","project_id","env_id","tenant_id","isolation_policy_id","trace_id"}
if required != expected_required:
    raise SystemExit(f"tenant_context_v2 required mismatch: {required} != {expected_required}")

cases = m.get("negative_cross_tenant_matrix", [])
if len(cases) < 3:
    raise SystemExit("insufficient negative cross-tenant cases")
for idx, case in enumerate(cases, start=1):
    if case.get("expected_decision") != "deny":
        raise SystemExit(f"case {idx} expected_decision must be deny")

report = {
    "status": "PASS",
    "tenant_model": m.get("tenant_model"),
    "validated_cases": len(cases),
    "required_fields": sorted(required),
}
Path("docs/governance/evidence/stage36_step1_tenant_contract_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("stage36 step1 tenant contract: PASS")
print(json.dumps(report, ensure_ascii=False))
PY

test -s "$REPORT_JSON"
