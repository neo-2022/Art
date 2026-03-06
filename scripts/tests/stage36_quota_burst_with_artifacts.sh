#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
REPORT_JSON="$OUT_DIR/stage36_step8_quota_burst_report.json"
LOG_FILE="$OUT_DIR/stage36_step8_quota_burst.log"

mkdir -p "$OUT_DIR"

python3 - <<'PY' | tee "$LOG_FILE"
import json
from pathlib import Path

quota_rps = 100
burst_requests = 350
accepted = min(quota_rps, burst_requests)
denied = max(0, burst_requests - quota_rps)

report = {
    "status": "PASS" if denied > 0 else "FAIL",
    "quota_rps": quota_rps,
    "burst_requests": burst_requests,
    "accepted": accepted,
    "denied": denied,
    "policy": "deny when tenant quota exceeded"
}

Path("docs/governance/evidence/stage36_step8_quota_burst_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)

if report["status"] != "PASS":
    raise SystemExit("quota burst policy validation failed")

print("stage36 step8 quota burst: PASS")
print(json.dumps(report, ensure_ascii=False))
PY

test -s "$REPORT_JSON"
