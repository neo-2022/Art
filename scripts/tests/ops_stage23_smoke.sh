#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
DB="$TMP_DIR/core.sqlite3"
ANALYTICS_STATE="$TMP_DIR/core.analytics.json"
BAK="$TMP_DIR/backups/core-$(date +%Y%m%d-%H%M%S).sqlite3"
PORT="${CORE_PORT:-18090}"
STARTUP_TIMEOUT_SECONDS="${CORE_STARTUP_TIMEOUT_SECONDS:-180}"
CONFIG_PATH="${CORE_CONFIG_PATH:-config/core.toml}"

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

wait_core_ready() {
  local deadline=$(( $(date +%s) + STARTUP_TIMEOUT_SECONDS ))
  while (( $(date +%s) < deadline )); do
    if curl -fsS "http://127.0.0.1:${PORT}/metrics" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done
  echo "core metrics readiness timeout on port ${PORT}" >&2
  if [[ -s /tmp/ops_stage23_core.log ]]; then
    tail -n 120 /tmp/ops_stage23_core.log >&2 || true
  fi
  return 1
}

start_core() {
  : >/tmp/ops_stage23_core.log
  cd "$ROOT_DIR"
  CORE_PORT="$PORT" \
  CORE_DB_PATH="$DB" \
  CORE_ANALYTICS_STATE_PATH="$ANALYTICS_STATE" \
  CORE_CONFIG_PATH="$CONFIG_PATH" \
  cargo run -p art-core >/tmp/ops_stage23_core.log 2>&1 &
  CORE_PID=$!
  wait_core_ready
}

stop_core() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  CORE_PID=""
}

snapshot_assert() {
  python3 - "$TMP_DIR/snapshot.json" "$TMP_DIR/snapshot_v2.json" "$TMP_DIR/incidents.json" "$TMP_DIR/audit_verify.json" "$TMP_DIR/audit.json" "$TMP_DIR/analytics.json" <<'PY'
import json
import pathlib
import sys

snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
snapshot_v2 = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
incidents = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
audit_verify = json.loads(pathlib.Path(sys.argv[4]).read_text(encoding="utf-8"))
audits = json.loads(pathlib.Path(sys.argv[5]).read_text(encoding="utf-8"))
analytics = json.loads(pathlib.Path(sys.argv[6]).read_text(encoding="utf-8"))

events = snapshot.get("events", [])
assert any(item.get("event", {}).get("kind") == "dr.smoke" for item in events), events
v2_events = snapshot_v2.get("events", [])
assert any(item.get("raw_event", {}).get("kind") == "dr.v2.smoke" for item in v2_events), v2_events
assert snapshot_v2.get("dna_clusters"), snapshot_v2
incident_items = incidents.get("items", [])
assert any(item.get("run_id") == "dr-run" and item.get("trace_id") == "dr-trace" for item in incident_items), incident_items
assert audit_verify.get("status") == "verified", audit_verify
assert audit_verify.get("count", 0) >= 2, audit_verify
audit_items = audits.get("items", [])
assert len(audit_items) >= 2, audit_items
assert any(item.get("action") == "service.status" for item in audit_items), audit_items
assert analytics.get("totals", {}).get("total_events", 0) >= 2, analytics
assert analytics.get("charts", {}).get("timeline"), analytics
print("ops-stage23-runtime-smoke: state validation OK")
PY
}

mkdir -p "$TMP_DIR/backups"
start_core

INGEST_V1_CODE="$(
  curl -sS -o "$TMP_DIR/ingest.json" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d '{"events":[{"kind":"dr.smoke","severity":"info","run_id":"dr-run","trace_id":"dr-trace","span_id":"dr-span","source_id":"dr:smoke","source_seq":1}]}' \
    "http://127.0.0.1:${PORT}/api/v1/ingest"
)"
[[ "$INGEST_V1_CODE" == "200" ]] || { echo "v1 ingest failed: $INGEST_V1_CODE"; cat "$TMP_DIR/ingest.json"; exit 1; }

INGEST_V2_CODE="$(
  curl -sS -o "$TMP_DIR/ingest_v2.json" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d '{"events":[{"kind":"dr.v2.smoke","severity":"warn","msg":"dr smoke v2","payload":{"service":"ops","region":"ru"},"evidence_blocks":[{"evidence_id":"ev-stage23-1","source_type":"log","source_ref":"log://stage23/dr-1","trust_score":0.9,"freshness_ms":1000,"redaction_policy_id":"default","access_scope":"public"}]}]}' \
    "http://127.0.0.1:${PORT}/api/v2/ingest"
)"
[[ "$INGEST_V2_CODE" == "200" ]] || { echo "v2 ingest failed: $INGEST_V2_CODE"; cat "$TMP_DIR/ingest_v2.json"; exit 1; }

ACTION_CODE="$(
  curl -sS -o "$TMP_DIR/action.json" -w "%{http_code}" \
    -H "content-type: application/json" \
    -H "x-action-preflight-id: pf-stage23-dr" \
    -H "x-actor-role: operator" \
    -d '{"action":"service.status","target":"core"}' \
    "http://127.0.0.1:${PORT}/api/v1/actions/execute"
)"
[[ "$ACTION_CODE" == "200" ]] || { echo "action execute failed: $ACTION_CODE"; cat "$TMP_DIR/action.json"; exit 1; }

curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$TMP_DIR/snapshot_before.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/incidents" >"$TMP_DIR/incidents_before.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/audit/verify" >"$TMP_DIR/audit_verify_before.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/audit" >"$TMP_DIR/audit_before.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v2/analytics/summary?window_minutes=120&top=5" >"$TMP_DIR/analytics_before.json"

curl -sS -N -H "x-core-stream-hold-seconds: 15" "http://127.0.0.1:${PORT}/api/v1/stream" >"$TMP_DIR/stream.log" 2>"$TMP_DIR/stream.err" &
STREAM_PID=$!
sleep 1

kill -HUP "$CORE_PID"
sleep 2
kill -0 "$CORE_PID" >/dev/null 2>&1 || { echo "core exited after SIGHUP"; exit 1; }
kill -0 "$STREAM_PID" >/dev/null 2>&1 || { echo "stream disconnected after SIGHUP"; exit 1; }

stop_core

sqlite3 "$DB" ".backup '$BAK'"
BAK_INTEGRITY="$(sqlite3 "$BAK" "PRAGMA integrity_check;")"
[[ -s "$BAK" ]] || { echo "backup file not created"; exit 1; }
[[ "$BAK_INTEGRITY" == "ok" ]] || { echo "backup integrity failed: $BAK_INTEGRITY"; exit 1; }

rm -f "$DB" "$DB-wal" "$DB-shm" "$ANALYTICS_STATE"
cp "$BAK" "$DB"
RESTORE_INTEGRITY="$(sqlite3 "$DB" "PRAGMA integrity_check;")"
[[ "$RESTORE_INTEGRITY" == "ok" ]] || { echo "restore integrity failed: $RESTORE_INTEGRITY"; exit 1; }

start_core

curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$TMP_DIR/snapshot.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v2/snapshot" >"$TMP_DIR/snapshot_v2.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/incidents" >"$TMP_DIR/incidents.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/audit/verify" >"$TMP_DIR/audit_verify.json"
curl -fsS -H "x-actor-role: admin" "http://127.0.0.1:${PORT}/api/v1/audit" >"$TMP_DIR/audit.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v2/analytics/summary?window_minutes=120&top=5" >"$TMP_DIR/analytics.json"
snapshot_assert

python3 - "$TMP_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
summary = {
    "backup_file": str(next(root.joinpath("backups").glob("core-*.sqlite3"))),
    "snapshot_before_events": len(json.loads(root.joinpath("snapshot_before.json").read_text(encoding="utf-8")).get("events", [])),
    "snapshot_after_events": len(json.loads(root.joinpath("snapshot.json").read_text(encoding="utf-8")).get("events", [])),
    "incidents_before": len(json.loads(root.joinpath("incidents_before.json").read_text(encoding="utf-8")).get("items", [])),
    "incidents_after": len(json.loads(root.joinpath("incidents.json").read_text(encoding="utf-8")).get("items", [])),
    "audit_verify_before": json.loads(root.joinpath("audit_verify_before.json").read_text(encoding="utf-8")).get("status"),
    "audit_verify_after": json.loads(root.joinpath("audit_verify.json").read_text(encoding="utf-8")).get("status"),
    "analytics_total_events_after": json.loads(root.joinpath("analytics.json").read_text(encoding="utf-8")).get("totals", {}).get("total_events"),
}
print(json.dumps(summary, ensure_ascii=False, indent=2))
PY

echo "ops-stage23-runtime-smoke: OK"
