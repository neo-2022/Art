#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step5_evidence_audit_trail.log"
REPORT_JSON="$OUT_DIR/stage36_step5_evidence_audit_trail_report.json"

mkdir -p "$OUT_DIR"

python3 - <<'PY' | tee "$LOG_FILE"
import json
from pathlib import Path

schema = json.loads(Path("docs/contracts/v2/schemas/evidence_access_audit_record_v2.json").read_text(encoding="utf-8"))
required = set(schema.get("required", []))
expected = {"evidence_id", "actor_role", "access_scope", "decision", "trace_id", "ts_ms"}
if required != expected:
    raise SystemExit(f"audit record required mismatch: {required} != {expected}")

sample = {
    "evidence_id": "ev-123",
    "actor_role": "sre",
    "access_scope": "tenant:alpha",
    "decision": "deny",
    "trace_id": "trc-stage36-audit-1",
    "ts_ms": 1772805600000
}

report = {
    "status": "PASS",
    "required_fields": sorted(required),
    "sample": sample
}
Path("docs/governance/evidence/stage36_step5_evidence_audit_trail_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("stage36 step5 evidence audit trail: PASS")
print(json.dumps(report, ensure_ascii=False))
PY

test -s "$REPORT_JSON"
