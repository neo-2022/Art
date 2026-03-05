#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
DB="$TMP_DIR/core.db"
BAK="$TMP_DIR/backups/core-$(date +%Y%m%d-%H%M).sqlite3"
RESTORED_DB="$TMP_DIR/core-restored.db"
PORT="${CORE_PORT:-18090}"

CORE_PID=""
STREAM_PID=""
cleanup() {
  if [[ -n "$STREAM_PID" ]] && kill -0 "$STREAM_PID" >/dev/null 2>&1; then
    kill "$STREAM_PID" >/dev/null 2>&1 || true
    wait "$STREAM_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR/backups"
sqlite3 "$DB" "create table if not exists t(id integer primary key, v text); insert into t(v) values ('x');"
sqlite3 "$DB" ".backup '$BAK'"
cp "$BAK" "$RESTORED_DB"

BAK_INTEGRITY="$(sqlite3 "$BAK" "PRAGMA integrity_check;")"
RESTORE_INTEGRITY="$(sqlite3 "$RESTORED_DB" "PRAGMA integrity_check;")"
[[ -s "$BAK" ]] || { echo "backup file not created"; exit 1; }
[[ "$BAK_INTEGRITY" == "ok" ]] || { echo "backup integrity failed: $BAK_INTEGRITY"; exit 1; }
[[ "$RESTORE_INTEGRITY" == "ok" ]] || { echo "restore integrity failed: $RESTORE_INTEGRITY"; exit 1; }

cd "$ROOT_DIR"
CORE_PORT="$PORT" cargo run -p art-core >/tmp/ops_stage23_core.log 2>&1 &
CORE_PID=$!

for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done
curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null

INGEST_CODE="$(
  curl -sS -o "$TMP_DIR/ingest.json" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d '{"events":[{"kind":"dr.smoke","severity":"info","run_id":"dr-run","trace_id":"dr-trace","span_id":"dr-span","source_id":"dr:smoke","source_seq":1}]}' \
    "http://127.0.0.1:${PORT}/api/v1/ingest"
)"
[[ "$INGEST_CODE" == "200" ]] || { echo "ingest failed: $INGEST_CODE"; cat "$TMP_DIR/ingest.json"; exit 1; }

curl -sS -N -H "x-core-stream-hold-seconds: 15" "http://127.0.0.1:${PORT}/api/v1/stream" >"$TMP_DIR/stream.log" &
STREAM_PID=$!
sleep 1

kill -HUP "$CORE_PID"
sleep 2
kill -0 "$CORE_PID" >/dev/null 2>&1 || { echo "core exited after SIGHUP"; exit 1; }
kill -0 "$STREAM_PID" >/dev/null 2>&1 || { echo "stream disconnected after SIGHUP"; exit 1; }

curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$TMP_DIR/snapshot.json"
python3 - "$TMP_DIR/snapshot.json" "$TMP_DIR/ingest.json" <<'PY'
import json
import pathlib
import sys

snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
ingest = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))

assert ingest.get("accepted") == 1, ingest
events = snapshot.get("events", [])
incidents = snapshot.get("incidents", [])
assert any(item.get("event", {}).get("kind") == "dr.smoke" for item in events), events
assert any(item.get("run_id") == "dr-run" and item.get("trace_id") == "dr-trace" for item in incidents), incidents
print("ops-stage23-runtime-smoke: snapshot validation OK")
PY

echo "ops-smoke: OK"
