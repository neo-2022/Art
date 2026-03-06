#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
CORE_LOG="$OUT_DIR/stage34_step6_core_regression.log"
INDEX_LOG="$OUT_DIR/stage34_step6_local_index_regression.log"
JSON_FILE="$OUT_DIR/stage34_step6_perf_regression_report.json"
MD_FILE="$OUT_DIR/stage34_step6_perf_regression_report.md"

mkdir -p "$OUT_DIR"

cargo test -p art-core stage34_snapshot_stream_perf_regression_report -- --ignored --nocapture \
  | tee "$CORE_LOG"

node > "$INDEX_LOG" <<'NODE'
const { createLocalStores } = require('./packages/local-stores/dist/index.js');

function percentile(values, q) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.floor(sorted.length * q);
  return sorted[Math.min(idx, sorted.length - 1)];
}

const stores = createLocalStores();
const total = 20000;
for (let i = 0; i < total; i += 1) {
  stores.cachePut({
    id: `ev-${i}`,
    dna_id: `dna-${i % 200}`,
    payload: { seq: i, service: `svc-${i % 17}` }
  });
}

const samples = [];
for (let i = 0; i < 4000; i += 1) {
  const dna = `dna-${i % 200}`;
  const started = process.hrtime.bigint();
  stores.findSimilarByDna(dna);
  const elapsedNs = process.hrtime.bigint() - started;
  samples.push(Number(elapsedNs) / 1e6);
}
const p95 = percentile(samples, 0.95);
const p99 = percentile(samples, 0.99);
console.log(`STAGE34_LOCAL_INDEX p95_ms=${p95.toFixed(3)} p99_ms=${p99.toFixed(3)} samples=${samples.length}`);
NODE

python3 - "$CORE_LOG" "$INDEX_LOG" "$JSON_FILE" "$MD_FILE" <<'PY'
import json
import re
import sys
from pathlib import Path

core_log = Path(sys.argv[1]).read_text(encoding="utf-8")
index_log = Path(sys.argv[2]).read_text(encoding="utf-8")
json_path = Path(sys.argv[3])
md_path = Path(sys.argv[4])

core_match = re.search(
    r"STAGE34_REGRESSION snapshot_ms=(\d+) stream_response_start_ms=(\d+) stream_total_ms=(\d+) stream_events=(\d+)",
    core_log,
)
if not core_match:
    raise SystemExit("Missing STAGE34_REGRESSION line")

idx_match = re.search(r"STAGE34_LOCAL_INDEX p95_ms=([0-9.]+) p99_ms=([0-9.]+) samples=(\d+)", index_log)
if not idx_match:
    raise SystemExit("Missing STAGE34_LOCAL_INDEX line")

snapshot_ms = int(core_match.group(1))
stream_response_start_ms = int(core_match.group(2))
stream_total_ms = int(core_match.group(3))
stream_events = int(core_match.group(4))
index_p95 = float(idx_match.group(1))
index_p99 = float(idx_match.group(2))
index_samples = int(idx_match.group(3))

budgets = {
    "snapshot_ms": 200,
    "stream_response_start_ms": 250,
    "index_p95_ms": 50.0,
}

status = {
    "snapshot_pass": snapshot_ms <= budgets["snapshot_ms"],
    "stream_pass": stream_response_start_ms <= budgets["stream_response_start_ms"],
    "index_pass": index_p95 <= budgets["index_p95_ms"],
}

if not all(status.values()):
    raise SystemExit(f"Stage34 regression budget failed: {status}")

payload = {
    "snapshot_ms": snapshot_ms,
    "stream_response_start_ms": stream_response_start_ms,
    "stream_total_ms": stream_total_ms,
    "stream_events": stream_events,
    "local_index_p95_ms": index_p95,
    "local_index_p99_ms": index_p99,
    "local_index_samples": index_samples,
    "budgets": budgets,
    "status": status,
}
json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

md_path.write_text(
    "# Stage34 Perf Regression Report\n\n"
    f"- snapshot_ms: {snapshot_ms} (budget <= {budgets['snapshot_ms']})\n"
    f"- stream_response_start_ms: {stream_response_start_ms} (budget <= {budgets['stream_response_start_ms']})\n"
    f"- stream_total_ms: {stream_total_ms} (diagnostic)\n"
    f"- stream_events: {stream_events}\n"
    f"- local_index_p95_ms: {index_p95:.3f} (budget <= {budgets['index_p95_ms']})\n"
    f"- local_index_p99_ms: {index_p99:.3f}\n"
    f"- verdict: PASS\n",
    encoding="utf-8",
)
print(f"stage34 perf regression report written: {md_path}")
PY
