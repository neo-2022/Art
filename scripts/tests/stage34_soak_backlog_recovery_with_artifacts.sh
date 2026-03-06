#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage34_step5_soak.log"
JSON_FILE="$OUT_DIR/stage34_step5_soak_report.json"
MD_FILE="$OUT_DIR/stage34_step5_soak_report.md"

mkdir -p "$OUT_DIR"

cargo test -p art-core stage34_v2_soak_backlog_recovery_zero_loss -- --ignored --nocapture \
  | tee "$LOG_FILE"

python3 - "$LOG_FILE" "$JSON_FILE" "$MD_FILE" <<'PY'
import json
import re
import sys
from pathlib import Path

log_path = Path(sys.argv[1])
json_path = Path(sys.argv[2])
md_path = Path(sys.argv[3])
text = log_path.read_text(encoding="utf-8")

m = re.search(
    r"STAGE34_SOAK total_events=(?P<total>\d+) accepted_total=(?P<accepted>\d+) forced_failures=(?P<failures>\d+) "
    r"backlog_retries=(?P<retries>\d+) zero_loss=(?P<zero>true|false) elapsed_sec=(?P<elapsed>\d+)",
    text,
)
if not m:
    raise SystemExit("STAGE34_SOAK summary not found in log")

row = {
    "total_events": int(m.group("total")),
    "accepted_total": int(m.group("accepted")),
    "forced_failures": int(m.group("failures")),
    "backlog_retries": int(m.group("retries")),
    "zero_loss": m.group("zero") == "true",
    "elapsed_sec": int(m.group("elapsed")),
}

if not row["zero_loss"]:
    raise SystemExit("zero-loss assertion failed")

json_path.write_text(json.dumps(row, ensure_ascii=False, indent=2), encoding="utf-8")
md_path.write_text(
    "# Stage34 Soak Report (backlog/recovery)\n\n"
    f"- total_events: {row['total_events']}\n"
    f"- accepted_total: {row['accepted_total']}\n"
    f"- forced_failures: {row['forced_failures']}\n"
    f"- backlog_retries: {row['backlog_retries']}\n"
    f"- zero_loss: {'PASS' if row['zero_loss'] else 'FAIL'}\n"
    f"- elapsed_sec: {row['elapsed_sec']}\n",
    encoding="utf-8",
)
print(f"stage34 soak report written: {md_path}")
PY
