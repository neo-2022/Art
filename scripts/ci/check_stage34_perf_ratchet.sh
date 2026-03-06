#!/usr/bin/env bash
set -euo pipefail

BASELINE_FILE="docs/source/perf_ratchet_baseline_v0_2.json"
ACTUAL_FILE="docs/governance/evidence/stage34_step6_perf_regression_report.json"
GATE_LOG="docs/governance/evidence/stage34_step7_ratchet_gate.log"

bash scripts/tests/stage34_perf_regression_with_artifacts.sh
bash scripts/tests/stage34_replay_regression_with_artifacts.sh
bash scripts/ci/check_stage34_innovation_kpi_gate.sh

python3 - "$BASELINE_FILE" "$ACTUAL_FILE" "$GATE_LOG" <<'PY'
import json
import sys
from pathlib import Path

baseline = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
actual = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
gate_log = Path(sys.argv[3])

metrics = ["snapshot_ms", "stream_response_start_ms", "local_index_p95_ms"]
results = []
failed = []
for metric in metrics:
    baseline_value = float(baseline["metrics"][metric])
    actual_value = float(actual[metric])
    threshold = baseline_value * 1.05
    passed = actual_value <= threshold
    row = {
        "metric": metric,
        "baseline": baseline_value,
        "actual": actual_value,
        "threshold": threshold,
        "pass": passed,
    }
    results.append(row)
    if not passed:
        failed.append(row)

lines = ["stage34 perf ratchet gate"]
for row in results:
    lines.append(
        f"{row['metric']}: baseline={row['baseline']:.6f} actual={row['actual']:.6f} "
        f"threshold={row['threshold']:.6f} pass={row['pass']}"
    )

if failed:
    lines.append("status=FAIL")
    gate_log.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(gate_log.read_text(encoding="utf-8"), end="")
    raise SystemExit(1)

lines.append("status=PASS")
gate_log.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(gate_log.read_text(encoding="utf-8"), end="")
PY
