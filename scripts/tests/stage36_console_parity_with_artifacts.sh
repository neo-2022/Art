#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step3_console_parity.log"
REPORT_JSON="$OUT_DIR/stage36_step3_console_parity_report.json"

mkdir -p "$OUT_DIR"

python3 - <<'PY' | tee "$LOG_FILE"
import json
from pathlib import Path

parity = json.loads(Path("docs/source/saas_console_api_parity_v0_2.json").read_text(encoding="utf-8"))
endpoints = parity.get("required_endpoints", [])
keys = parity.get("required_response_keys", [])

if len(endpoints) < 6:
    raise SystemExit("parity endpoints list is incomplete")
for ep in ["/api/v1/snapshot", "/api/v2/snapshot", "/api/v1/stream", "/api/v2/stream"]:
    if ep not in endpoints:
        raise SystemExit(f"missing parity endpoint: {ep}")
for k in ["cursor", "effective_profile_id", "events"]:
    if k not in keys:
        raise SystemExit(f"missing required response key: {k}")

report = {
    "status": "PASS",
    "checked_endpoints": endpoints,
    "required_response_keys": keys,
    "parity_scope": parity.get("parity_scope"),
}
Path("docs/governance/evidence/stage36_step3_console_parity_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("stage36 step3 console parity: PASS")
print(json.dumps(report, ensure_ascii=False))
PY

test -s "$REPORT_JSON"
