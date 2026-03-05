#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${CORE_PORT:-18080}"

cd "$ROOT_DIR"

CORE_PORT="$PORT" cargo run -p art-core >/tmp/pack_regart_runtime_api_core.log 2>&1 &
CORE_PID=$!
cleanup() {
  if kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done
curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null

python3 - "$PORT" <<'PY'
import json
import pathlib
import sys
import tomllib
import urllib.request

port = int(sys.argv[1])
root = pathlib.Path.cwd()
fixtures_dir = root / "packs" / "regart" / "fixtures"
examples_toml = root / "packs" / "regart" / "examples" / "receivers.toml"

required_fixtures = [
    "ui_proxy_unavailable.json",
    "upstream_error.json",
    "ui.graph.empty.json",
    "network_error.json",
    "tools_event.json",
    "models_event.json",
    "graph_event.json",
]

events = []
expected = set()
for name in required_fixtures:
    data = json.loads((fixtures_dir / name).read_text(encoding="utf-8"))
    if "severity" not in data:
        data["severity"] = "info"
    if "kind" not in data:
        data["kind"] = "regart.fixture"
    events.append(data)
    expected.add((data["run_id"], data["trace_id"], data["span_id"]))

payload = json.dumps({"events": events}).encode("utf-8")
ingest_req = urllib.request.Request(
    f"http://127.0.0.1:{port}/api/v1/ingest",
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST",
)
with urllib.request.urlopen(ingest_req, timeout=10) as resp:
    assert resp.status == 200, f"ingest status={resp.status}"
    body = json.loads(resp.read().decode("utf-8"))
    assert body.get("accepted") == len(events), body

with urllib.request.urlopen(f"http://127.0.0.1:{port}/api/v1/incidents", timeout=10) as resp:
    assert resp.status == 200, f"incidents status={resp.status}"
    body = json.loads(resp.read().decode("utf-8"))
    items = body.get("items", [])

actual = set()
for item in items:
    run_id = item.get("run_id")
    trace_id = item.get("trace_id")
    span_id = item.get("span_id")
    if run_id and trace_id and span_id:
        actual.add((run_id, trace_id, span_id))

missing = expected - actual
assert not missing, f"missing correlation tuples in incidents: {missing}"

cfg = tomllib.loads(examples_toml.read_text(encoding="utf-8"))
kinds = {row["kind"] for row in cfg["receivers"]}
assert {"journald", "file_tail", "stdout_stderr", "net_probe"}.issubset(kinds), kinds

print("pack-regart-runtime-api: OK")
PY
