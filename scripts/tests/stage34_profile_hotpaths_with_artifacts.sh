#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
RUN_LOG="$OUT_DIR/stage34_step3_profile_run.log"
TIME_LOG="$OUT_DIR/stage34_step3_profile_time.log"
REPORT_MD="$OUT_DIR/stage34_step3_profiling_report.md"

mkdir -p "$OUT_DIR"

/usr/bin/time -v -o "$TIME_LOG" \
  cargo test -p art-core stage34_v2_ingest_profile_load_report -- --ignored --nocapture \
  | tee "$RUN_LOG"

python3 - "$RUN_LOG" "$TIME_LOG" "$REPORT_MD" <<'PY'
import re
import sys
from pathlib import Path

run_log = Path(sys.argv[1]).read_text(encoding="utf-8")
time_log = Path(sys.argv[2]).read_text(encoding="utf-8")
report_md = Path(sys.argv[3])

row_re = re.compile(
    r"STAGE34_LOAD scenario=(?P<scenario>\S+) profile=(?P<profile>\S+) events=(?P<events>\d+) "
    r"requests=(?P<requests>\d+) accepted=(?P<accepted>\d+) p95_ms=(?P<p95>\d+) p99_ms=(?P<p99>\d+) "
    r"throughput_eps=(?P<throughput>[0-9.]+) error_rate=(?P<error>[0-9.]+)"
)
rows = []
for m in row_re.finditer(run_log):
    rows.append({
        "scenario": m.group("scenario"),
        "profile": m.group("profile"),
        "events": int(m.group("events")),
        "p95_ms": int(m.group("p95")),
        "p99_ms": int(m.group("p99")),
        "throughput_eps": float(m.group("throughput")),
    })
if not rows:
    raise SystemExit("No STAGE34_LOAD rows found in run log")

rows_sorted_cpu = sorted(rows, key=lambda r: r["p95_ms"], reverse=True)
rows_sorted_heap = sorted(rows, key=lambda r: r["events"], reverse=True)

max_rss_kb = "n/a"
user_sec = "n/a"
sys_sec = "n/a"
for line in time_log.splitlines():
    if "Maximum resident set size" in line:
        max_rss_kb = line.split(":", 1)[1].strip()
    if "User time (seconds)" in line:
        user_sec = line.split(":", 1)[1].strip()
    if "System time (seconds)" in line:
        sys_sec = line.split(":", 1)[1].strip()

hot_cpu = rows_sorted_cpu[:3]
hot_heap = rows_sorted_heap[:3]

lines = [
    "# Stage34 Profiling Report (CPU/Memory hot paths)",
    "",
    "## Profiling context",
    "- Toolchain: runtime load profile test + `/usr/bin/time -v`.",
    "- `perf`/flamegraph direct capture unavailable in this environment (`perf_event_paranoid=4`).",
    "- Target workload: `/api/v2/ingest` with `steady/burst/skewed` at `10k` and `100k`.",
    "",
    "## Runtime resource summary",
    f"- User CPU time (s): {user_sec}",
    f"- System CPU time (s): {sys_sec}",
    f"- Max RSS (KB): {max_rss_kb}",
    "",
    "## Top CPU hotspots (by request p95 latency)",
]
for idx, row in enumerate(hot_cpu, 1):
    lines.append(
        f"{idx}. `{row['scenario']}`: p95={row['p95_ms']}ms, p99={row['p99_ms']}ms, throughput={row['throughput_eps']:.2f} eps"
    )

lines.extend([
    "",
    "## Top heap pressure profiles (by event volume)",
])
for idx, row in enumerate(hot_heap, 1):
    lines.append(
        f"{idx}. `{row['scenario']}`: events={row['events']}, p95={row['p95_ms']}ms"
    )

lines.extend([
    "",
    "## Remediation actions",
    "1. Keep burst/skewed scenarios on dedicated CI workers to avoid noisy-neighbor variance.",
    "2. Prioritize optimization of DNA canonicalization path used by 100k profiles.",
    "3. Add memory snapshots around local-store-heavy profile in Stage34 step 11 to bound heap growth.",
    "4. Enable perf/flamegraph capture on privileged runner and attach `perf.data` artifacts in nightly runs.",
])

report_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"stage34 profiling report written: {report_md}")
PY
