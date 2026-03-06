#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
REPORT_JSON="$OUT_DIR/stage34_step13_innovation_kpi_report.json"
REPORT_MD="$OUT_DIR/stage34_step13_innovation_kpi_report.md"

mkdir -p "$OUT_DIR"

python3 - "$REPORT_JSON" "$REPORT_MD" <<'PY'
import json
import re
import sys
from pathlib import Path

report_json = Path(sys.argv[1])
report_md = Path(sys.argv[2])

rtp_report = Path("docs/governance/evidence/stage30_step10_rtp_experiment_report.md").read_text(encoding="utf-8")
lrc_report = Path("docs/governance/evidence/stage31_step6_lrc_mismatch_report.md").read_text(encoding="utf-8")
nrac_report = Path("docs/governance/evidence/stage33_step6_nrac_evaluation_report.md").read_text(encoding="utf-8")

rtp_pass = "PASS" in rtp_report
nrac_pass = "Result: PASS" in nrac_report

step_lines = [line for line in lrc_report.splitlines() if line.startswith("| ") and "step_id" not in line and "---" not in line]
total_steps = len(step_lines)
invalid_steps = 0
for line in step_lines:
    cells = [c.strip() for c in line.strip("| ").split("|")]
    if len(cells) >= 2 and cells[1] == "invalid":
        invalid_steps += 1

metrics = {
    "false_positive_rate": 0.0 if rtp_pass else 1.0,
    "runbook_mismatch_rate": (invalid_steps / total_steps) if total_steps else 1.0,
    "rollback_rate": 0.0 if nrac_pass else 1.0,
}

payload = {
    "sources": {
        "rtp": "docs/governance/evidence/stage30_step10_rtp_experiment_report.md",
        "lrc": "docs/governance/evidence/stage31_step6_lrc_mismatch_report.md",
        "nrac": "docs/governance/evidence/stage33_step6_nrac_evaluation_report.md",
    },
    "metrics": metrics,
    "notes": {
        "lrc_total_steps": total_steps,
        "lrc_invalid_steps": invalid_steps,
    },
}

report_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
report_md.write_text(
    "# Stage34 Innovation KPI Report\n\n"
    f"- false_positive_rate: {metrics['false_positive_rate']:.4f}\n"
    f"- runbook_mismatch_rate: {metrics['runbook_mismatch_rate']:.4f} ({invalid_steps}/{total_steps})\n"
    f"- rollback_rate: {metrics['rollback_rate']:.4f}\n",
    encoding="utf-8",
)
print(f"stage34 innovation KPI report written: {report_md}")
PY
