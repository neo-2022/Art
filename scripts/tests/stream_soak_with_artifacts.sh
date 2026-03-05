#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-artifacts/stage14-soak}"
mkdir -p "$OUT_DIR"

run_case() {
  local name="$1"
  shift
  local log_file="$OUT_DIR/${name}.log"
  echo "== ${name} ==" | tee "$log_file"
  /usr/bin/time -v "$@" 2>&1 | tee -a "$log_file"
}

run_case stream_10k_events \
  cargo test -p art-core stream_load_10k_events_single_subscriber -- --nocapture

run_case stream_1000_subscribers_60s \
  cargo test -p art-core stream_load_1000_subscribers_60s -- --ignored --nocapture

python3 - "$OUT_DIR" <<'PY'
import json
import pathlib
import re
import sys

out_dir = pathlib.Path(sys.argv[1])
log_10k = (out_dir / "stream_10k_events.log").read_text(encoding="utf-8")
log_1000 = (out_dir / "stream_1000_subscribers_60s.log").read_text(encoding="utf-8")

def parse_wall_time(text: str) -> str:
    m = re.search(r"Elapsed \(wall clock\) time.*?:\s*([0-9:.\-]+)", text)
    return m.group(1) if m else "unknown"

summary = {
    "stream_10k_events": {
        "passed": "test result: ok" in log_10k,
        "wall_time": parse_wall_time(log_10k),
    },
    "stream_1000_subscribers_60s": {
        "passed": "test result: ok" in log_1000 and "stream_1000_subscribers_60s total=" in log_1000,
        "wall_time": parse_wall_time(log_1000),
    },
}
(out_dir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
(out_dir / "README.txt").write_text(
    "Stage14 soak artifacts:\n"
    "- stream_10k_events.log\n"
    "- stream_1000_subscribers_60s.log\n"
    "- summary.json\n",
    encoding="utf-8",
)
if not all(item["passed"] for item in summary.values()):
    raise SystemExit("soak summary contains failed scenarios")
PY

echo "stage14 soak artifacts: OK ($OUT_DIR)"
