#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage34_step4_overload.log"
JSON_FILE="$OUT_DIR/stage34_step4_overload_report.json"
MD_FILE="$OUT_DIR/stage34_step4_overload_report.md"

mkdir -p "$OUT_DIR"

cargo test -p art-core stage34_v2_overload_degradation_report -- --ignored --nocapture \
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

row_re = re.compile(
    r"STAGE34_OVERLOAD factor=(?P<factor>\d+)x events=(?P<events>\d+) requests=(?P<requests>\d+) accepted=(?P<accepted>\d+) "
    r"p95_ms=(?P<p95>\d+) p99_ms=(?P<p99>\d+) throughput_eps=(?P<throughput>[0-9.]+) budget_p95_ms=(?P<budget>\d+) data_path_ok=(?P<ok>true|false)"
)
rows = []
for m in row_re.finditer(text):
    rows.append({
        "factor": int(m.group("factor")),
        "events": int(m.group("events")),
        "requests": int(m.group("requests")),
        "accepted": int(m.group("accepted")),
        "p95_ms": int(m.group("p95")),
        "p99_ms": int(m.group("p99")),
        "throughput_eps": float(m.group("throughput")),
        "budget_p95_ms": int(m.group("budget")),
        "data_path_ok": m.group("ok") == "true",
    })

if {2, 3} != {r["factor"] for r in rows}:
    raise SystemExit("Missing 2x or 3x overload scenario in log")

for row in rows:
    if not row["data_path_ok"]:
        raise SystemExit(f"Data path not OK for factor {row['factor']}x")
    if row["p95_ms"] > row["budget_p95_ms"]:
        raise SystemExit(f"p95 budget exceeded for factor {row['factor']}x")

rows = sorted(rows, key=lambda r: r["factor"])
ratio = (rows[1]["p95_ms"] / rows[0]["p95_ms"]) if rows[0]["p95_ms"] else 1.0

payload = {
    "rows": rows,
    "degradation_ratio_p95_3x_to_2x": ratio,
    "status": "PASS"
}
json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

lines = [
    "# Stage34 Overload Report (2x/3x)",
    "",
    "| factor | events | requests | accepted | p95_ms | p99_ms | throughput_eps | budget_p95_ms | data_path_ok |",
    "|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
]
for row in rows:
    lines.append(
        f"| {row['factor']}x | {row['events']} | {row['requests']} | {row['accepted']} | "
        f"{row['p95_ms']} | {row['p99_ms']} | {row['throughput_eps']:.2f} | {row['budget_p95_ms']} | "
        f"{'PASS' if row['data_path_ok'] else 'FAIL'} |"
    )
lines.append("")
lines.append(f"- p95 degradation ratio (3x/2x): {ratio:.3f}")
lines.append("- Verdict: PASS (controlled degradation, no data-path loss)")
md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"stage34 overload report written: {md_path}")
PY
