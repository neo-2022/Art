#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT_DIR/target/debug/art-core"
TMP_DIR="$(mktemp -d)"
PORT="${CORE_PORT:-18110}"
STARTUP_TIMEOUT_SECONDS="${CORE_STARTUP_TIMEOUT_SECONDS:-120}"
CORE_PID=""
LOADER_PID=""
STOP_FILE="$TMP_DIR/stop-loader"
ACCEPTED_FILE="$TMP_DIR/accepted-count.txt"
PREKILL_TRACE_FILE="$TMP_DIR/prekill-traces.jsonl"
POSTKILL_TRACE="stage11-recovery-$(date +%s)"

cleanup() {
  touch "$STOP_FILE" >/dev/null 2>&1 || true
  if [[ -n "$LOADER_PID" ]] && kill -0 "$LOADER_PID" >/dev/null 2>&1; then
    kill "$LOADER_PID" >/dev/null 2>&1 || true
    wait "$LOADER_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wait_http_ok() {
  local url="$1"
  local timeout_seconds="${2:-60}"
  local deadline=$(( $(date +%s) + timeout_seconds ))
  while (( $(date +%s) < deadline )); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  echo "timeout waiting for $url" >&2
  return 1
}

write_config_global() {
  cat >"$1" <<'EOF'
profile_id = "global"
retention_days = 30
export_mode = "standard"
egress_policy = "controlled"
residency = "any"
updates_mode = "online"
EOF
}

start_core() {
  local cfg="$1"
  local db_path="$2"
  local analytics_path="$3"
  local log_path="$4"
  CORE_CONFIG_PATH="$cfg" \
  CORE_PORT="$PORT" \
  CORE_HOST="127.0.0.1" \
  CORE_DB_PATH="$db_path" \
  CORE_ANALYTICS_STATE_PATH="$analytics_path" \
  "$BIN" >"$log_path" 2>&1 &
  CORE_PID="$!"
  wait_http_ok "http://127.0.0.1:${PORT}/health" "$STARTUP_TIMEOUT_SECONDS"
}

python3 - <<'PY' >/dev/null
import sys
print("python-ok")
PY

echo "[stage11-kill9] build art-core"
cargo build -p art-core >/dev/null

CFG="$TMP_DIR/core.toml"
DB_PATH="$TMP_DIR/core.sqlite3"
ANALYTICS_PATH="$TMP_DIR/analytics.json"
CORE_LOG="$TMP_DIR/core.log"
write_config_global "$CFG"
touch "$ACCEPTED_FILE"
echo "0" >"$ACCEPTED_FILE"
touch "$PREKILL_TRACE_FILE"

echo "[stage11-kill9] start core"
start_core "$CFG" "$DB_PATH" "$ANALYTICS_PATH" "$CORE_LOG"

echo "[stage11-kill9] warmup ingest"
WARMUP_RESP="$TMP_DIR/warmup.json"
WARMUP_CODE="$(
  curl -sS -o "$WARMUP_RESP" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d '{"events":[{"severity":"info","kind":"stage11.warmup","trace_id":"stage11-warmup","msg":"warmup"}]}' \
    "http://127.0.0.1:${PORT}/api/v1/ingest"
)"
[[ "$WARMUP_CODE" == "200" ]] || { echo "warmup ingest failed: $WARMUP_CODE"; cat "$WARMUP_RESP"; exit 1; }

echo "[stage11-kill9] start background ingest load"
python3 - "$PORT" "$STOP_FILE" "$ACCEPTED_FILE" "$PREKILL_TRACE_FILE" <<'PY' &
from __future__ import annotations

import json
import pathlib
import sys
import time
import urllib.error
import urllib.request

port = int(sys.argv[1])
stop_file = pathlib.Path(sys.argv[2])
accepted_file = pathlib.Path(sys.argv[3])
trace_file = pathlib.Path(sys.argv[4])
base = f"http://127.0.0.1:{port}/api/v1/ingest"
accepted = 0

while not stop_file.exists():
    trace_id = f"stage11-live-{int(time.time() * 1000)}-{accepted + 1}"
    payload = json.dumps(
        {
            "events": [
                {
                    "severity": "info",
                    "kind": "stage11.kill9.live",
                    "trace_id": trace_id,
                    "msg": "live ingest before kill -9",
                }
            ]
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        base,
        data=payload,
        headers={"content-type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=1.0) as resp:
            if resp.status == 200:
                accepted += 1
                accepted_file.write_text(str(accepted), encoding="utf-8")
                with trace_file.open("a", encoding="utf-8") as fh:
                    fh.write(json.dumps({"trace_id": trace_id}) + "\n")
    except Exception:
        time.sleep(0.03)
        continue
    time.sleep(0.02)
PY
LOADER_PID="$!"

deadline=$(( $(date +%s) + 15 ))
while (( $(date +%s) < deadline )); do
  accepted="$(cat "$ACCEPTED_FILE" 2>/dev/null || echo 0)"
  if [[ "${accepted:-0}" =~ ^[0-9]+$ ]] && (( accepted >= 5 )); then
    break
  fi
  sleep 0.1
done
accepted="$(cat "$ACCEPTED_FILE" 2>/dev/null || echo 0)"
if ! [[ "${accepted:-0}" =~ ^[0-9]+$ ]] || (( accepted < 1 )); then
  echo "background ingest never accepted an event before kill -9" >&2
  tail -n 80 "$CORE_LOG" >&2 || true
  exit 1
fi

echo "[stage11-kill9] kill -9 core during active ingest (accepted_before_kill=$accepted)"
kill -9 "$CORE_PID"
wait "$CORE_PID" >/dev/null 2>&1 || true
CORE_PID=""

touch "$STOP_FILE"
wait "$LOADER_PID" >/dev/null 2>&1 || true
LOADER_PID=""

python3 - "$DB_PATH" <<'PY'
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

db_path = Path(sys.argv[1])
conn = sqlite3.connect(str(db_path))
try:
    row = conn.execute("PRAGMA integrity_check;").fetchone()
    assert row and row[0] == "ok", row
finally:
    conn.close()
PY

echo "[stage11-kill9] restart core"
RESTART_LOG="$TMP_DIR/core-restart.log"
start_core "$CFG" "$DB_PATH" "$ANALYTICS_PATH" "$RESTART_LOG"

RECOVERY_RESP="$TMP_DIR/recovery.json"
RECOVERY_CODE="$(
  curl -sS -o "$RECOVERY_RESP" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d "{\"events\":[{\"severity\":\"info\",\"kind\":\"stage11.kill9.recovered\",\"trace_id\":\"${POSTKILL_TRACE}\",\"msg\":\"post-kill restart recovery\"}]}" \
    "http://127.0.0.1:${PORT}/api/v1/ingest"
)"
[[ "$RECOVERY_CODE" == "200" ]] || { echo "recovery ingest failed: $RECOVERY_CODE"; cat "$RECOVERY_RESP"; exit 1; }

SNAPSHOT="$TMP_DIR/snapshot.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$SNAPSHOT"
python3 - "$SNAPSHOT" "$PREKILL_TRACE_FILE" "$POSTKILL_TRACE" <<'PY'
from __future__ import annotations

import json
import pathlib
import sys

snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
trace_file = pathlib.Path(sys.argv[2])
postkill_trace = sys.argv[3]
events = snapshot.get("events", [])
event_traces = {item.get("event", {}).get("trace_id") for item in events}

prekill_traces = []
for line in trace_file.read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    prekill_traces.append(json.loads(line)["trace_id"])

assert prekill_traces, "no accepted pre-kill traces recorded"
assert any(trace in event_traces for trace in prekill_traces), "no pre-kill accepted traces survived restart"
assert postkill_trace in event_traces, "post-kill recovery event missing from snapshot"
PY

python3 - "$DB_PATH" <<'PY'
from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

db_path = Path(sys.argv[1])
conn = sqlite3.connect(str(db_path))
try:
    row = conn.execute("PRAGMA integrity_check;").fetchone()
    assert row and row[0] == "ok", row
finally:
    conn.close()
PY

echo "stage11-kill9-runtime: OK"
echo "accepted_before_kill=$(cat "$ACCEPTED_FILE")"
echo "snapshot_contains_recovery_trace=${POSTKILL_TRACE}"
