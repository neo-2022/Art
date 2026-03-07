#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
PORT="${CORE_PORT:-18423}"
DB="$TMP_DIR/core.sqlite3"
ANALYTICS_STATE="$TMP_DIR/core.analytics.json"
CERT="$TMP_DIR/tls.crt"
KEY="$TMP_DIR/tls.key"
BROKEN_KEY="$TMP_DIR/tls-broken.key"
BACKLOG="$(python3 - <<'PY' "$DB"
from pathlib import Path
import sys
print(Path(sys.argv[1]).with_suffix(".startup_backlog.json"))
PY
)"
CORE_PID=""

cleanup() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wait_https_ready() {
  local deadline=$(( $(date +%s) + 40 ))
  while (( $(date +%s) < deadline )); do
    if curl -ksSf "https://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done
  echo "https readiness timeout on port ${PORT}" >&2
  [[ -s "$TMP_DIR/core.log" ]] && tail -n 120 "$TMP_DIR/core.log" >&2 || true
  return 1
}

start_core_tls() {
  : >"$TMP_DIR/core.log"
  cd "$ROOT_DIR"
  CORE_PORT="$PORT" \
  CORE_HOST="127.0.0.1" \
  CORE_DB_PATH="$DB" \
  CORE_ANALYTICS_STATE_PATH="$ANALYTICS_STATE" \
  CORE_TLS_CERT_PATH="$CERT" \
  CORE_TLS_KEY_PATH="$1" \
  cargo run -p art-core >"$TMP_DIR/core.log" 2>&1 &
  CORE_PID=$!
}

stop_core() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  CORE_PID=""
}

openssl req -x509 -newkey rsa:2048 -sha256 -days 1 -nodes \
  -subj "/CN=127.0.0.1" \
  -keyout "$KEY" \
  -out "$CERT" >/dev/null 2>&1
: > "$BROKEN_KEY"

start_core_tls "$BROKEN_KEY"
set +e
wait "$CORE_PID"
BROKEN_EXIT=$?
set -e
CORE_PID=""
[[ "$BROKEN_EXIT" -ne 0 ]] || { echo "core unexpectedly started with broken TLS key"; exit 1; }
[[ -f "$BACKLOG" ]] || { echo "startup backlog file not created"; exit 1; }

python3 - <<'PY' "$BACKLOG" "$CERT" "$BROKEN_KEY"
import json
import pathlib
import sys

backlog = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert len(backlog) == 1, backlog
entry = backlog[0]
assert entry["kind"] == "observability_gap.tls_config_invalid", entry
details = entry["details"]
assert details["component"] == "core/tls", details
assert details["reason"] == "cert_key_mismatch", details
assert details["stage"] == "startup_tls_bootstrap", details
assert details["cert_path"] == sys.argv[2], details
assert details["key_path"] == sys.argv[3], details
assert details["error"], details
assert details["trace_id"].startswith("tls-config-invalid-"), details
print("tls-config-invalid-startup-backlog: persisted")
PY

start_core_tls "$KEY"
wait_https_ready
curl -ksSf "https://127.0.0.1:${PORT}/api/v1/snapshot" >"$TMP_DIR/snapshot.json"

python3 - <<'PY' "$TMP_DIR/snapshot.json" "$CERT" "$BROKEN_KEY"
import json
import pathlib
import sys

snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
events = snapshot.get("events", [])
matches = [
    item for item in events
    if item.get("event", {}).get("kind") == "observability_gap.tls_config_invalid"
]
assert matches, events
details = matches[0]["event"]["details"]
assert details["startup_backlog"] is True, details
assert details["cert_path"] == sys.argv[2], details
assert details["key_path"] == sys.argv[3], details
assert details["error"], details
assert details["trace_id"].startswith("tls-config-invalid-"), details
print("tls-config-invalid-startup-backlog: published")
PY

[[ ! -f "$BACKLOG" ]] || { echo "startup backlog file still present after replay"; exit 1; }

python3 - <<'PY' "$TMP_DIR/snapshot.json"
import json
import pathlib
import sys

snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
summary = {
    "events_after_start": len(snapshot.get("events", [])),
    "tls_config_invalid_present": any(
        item.get("event", {}).get("kind") == "observability_gap.tls_config_invalid"
        for item in snapshot.get("events", [])
    ),
}
print(json.dumps(summary, ensure_ascii=False, indent=2))
PY

echo "tls-config-invalid-runtime-smoke: OK"
