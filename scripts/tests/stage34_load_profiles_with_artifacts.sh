#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage34_step2_load_profiles.log"
JSON_FILE="$OUT_DIR/stage34_step2_load_report.json"
MD_FILE="$OUT_DIR/stage34_step2_load_report.md"

mkdir -p "$OUT_DIR"

cargo test -p art-core stage34_v2_ingest_profile_load_report -- --ignored --nocapture \
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

pattern = re.compile(
    r"STAGE34_LOAD scenario=(?P<scenario>\S+) profile=(?P<profile>\S+) events=(?P<events>\d+) "
    r"requests=(?P<requests>\d+) accepted=(?P<accepted>\d+) p95_ms=(?P<p95>\d+) p99_ms=(?P<p99>\d+) "
    r"throughput_eps=(?P<throughput>[0-9.]+) error_rate=(?P<error>[0-9.]+) "
    r"snapshot_events=(?P<snapshot_events>\d+) snapshot_clusters=(?P<snapshot_clusters>\d+)"
)

rows = []
for m in pattern.finditer(text):
    row = {
        "scenario": m.group("scenario"),
        "profile": m.group("profile"),
        "events": int(m.group("events")),
        "requests": int(m.group("requests")),
        "accepted": int(m.group("accepted")),
        "p95_ms": int(m.group("p95")),
        "p99_ms": int(m.group("p99")),
        "throughput_eps": float(m.group("throughput")),
        "error_rate": float(m.group("error")),
        "snapshot_events": int(m.group("snapshot_events")),
        "snapshot_clusters": int(m.group("snapshot_clusters")),
    }
    row["budget_p95_ms"] = 120 if row["events"] == 10_000 else 350
    row["budget_pass"] = row["p95_ms"] <= row["budget_p95_ms"]
    rows.append(row)

expected = {
    "steady-10k",
    "steady-100k",
    "burst-10k",
    "burst-100k",
    "skewed-10k",
    "skewed-100k",
}
seen = {row["scenario"] for row in rows}
missing = sorted(expected - seen)
if missing:
    raise SystemExit(f"Missing scenarios in stage34 output: {missing}")

if not all(row["budget_pass"] for row in rows):
    bad = [row["scenario"] for row in rows if not row["budget_pass"]]
    raise SystemExit(f"Budget failed for scenarios: {bad}")

json_path.write_text(
    json.dumps({"generated_at": "stage34", "rows": rows}, ensure_ascii=False, indent=2),
    encoding="utf-8",
)

lines = [
    "# Stage34 Load Report (ingest v2 + dna clustering)",
    "",
    "| scenario | profile | events | requests | p95_ms | p99_ms | throughput_eps | budget_p95_ms | pass |",
    "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
]
for row in rows:
    lines.append(
        f"| {row['scenario']} | {row['profile']} | {row['events']} | {row['requests']} | "
        f"{row['p95_ms']} | {row['p99_ms']} | {row['throughput_eps']:.2f} | "
        f"{row['budget_p95_ms']} | {'PASS' if row['budget_pass'] else 'FAIL'} |"
    )

md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"stage34 load report written: {md_path}")
print(f"stage34 load report json: {json_path}")
PY
