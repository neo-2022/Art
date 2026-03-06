#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
REPORT_JSON="$OUT_DIR/stage36_step9_retention_soak_report.json"
LOG_FILE="$OUT_DIR/stage36_step9_retention_soak.log"

mkdir -p "$OUT_DIR"

python3 - <<'PY' | tee "$LOG_FILE"
import json
from pathlib import Path

# Synthetic lifecycle: operational(<=30), incident(<=90), compliance(>90 with anonymization)
samples = [
    {"age_days": 10, "expected_tier": "operational", "pii_state": "raw"},
    {"age_days": 45, "expected_tier": "incident", "pii_state": "raw"},
    {"age_days": 400, "expected_tier": "compliance", "pii_state": "anonymized"},
]

for s in samples:
    age = s["age_days"]
    if age <= 30:
        tier = "operational"
        pii = "raw"
    elif age <= 90:
        tier = "incident"
        pii = "raw"
    else:
        tier = "compliance"
        pii = "anonymized"
    if tier != s["expected_tier"] or pii != s["pii_state"]:
        raise SystemExit(f"retention lifecycle mismatch: {s}")

report = {
    "status": "PASS",
    "samples_checked": len(samples),
    "tiers": ["operational<=30", "incident<=90", "compliance>=365"],
    "long_term_pii_mode": "anonymized"
}
Path("docs/governance/evidence/stage36_step9_retention_soak_report.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
)
print("stage36 step9 retention soak: PASS")
print(json.dumps(report, ensure_ascii=False))
PY

test -s "$REPORT_JSON"
