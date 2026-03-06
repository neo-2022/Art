#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage34_step12_replay_regression.log"
JSON_FILE="$OUT_DIR/stage34_step12_replay_regression_report.json"
MD_FILE="$OUT_DIR/stage34_step12_replay_regression_report.md"

mkdir -p "$OUT_DIR"

bash scripts/ci/run_stage29_replay_determinism.sh | tee "$OUT_DIR/stage34_step12_replay_suite.log"

cargo test -p art-core stage34_replay_determinism_against_baseline -- --nocapture \
  | tee "$LOG_FILE"

python3 - "$LOG_FILE" "$JSON_FILE" "$MD_FILE" <<'PY'
import json
import re
import sys
from pathlib import Path

log_text = Path(sys.argv[1]).read_text(encoding='utf-8')
json_path = Path(sys.argv[2])
md_path = Path(sys.argv[3])

m = re.search(r"STAGE34_REPLAY_BASELINE baseline_hash=([0-9a-f]{64}) run_hash=([0-9a-f]{64}) match=(true|false)", log_text)
if not m:
    raise SystemExit('Replay baseline summary line not found')

baseline_hash, run_hash, match_raw = m.groups()
match = match_raw == 'true'
if not match:
    raise SystemExit('Replay baseline mismatch')

payload = {
    "baseline_hash": baseline_hash,
    "run_hash": run_hash,
    "match": match,
    "status": "PASS"
}
json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
md_path.write_text(
    "# Stage34 Replay Regression Report\n\n"
    f"- baseline_hash: `{baseline_hash}`\n"
    f"- run_hash: `{run_hash}`\n"
    f"- match: {'PASS' if match else 'FAIL'}\n",
    encoding='utf-8'
)
print(f"stage34 replay regression report written: {md_path}")
PY
