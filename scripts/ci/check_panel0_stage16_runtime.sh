#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT_DIR/target/debug/art-core"
TMP_DIR="$(mktemp -d)"
PORT="${CORE_PORT:-38160}"
PID=""

cleanup() {
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" || true
    wait "$PID" || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wait_http_ok() {
  local url="$1"
  for _ in $(seq 1 80); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
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

http_get() {
  local url="$1"
  local body_out="$2"
  local headers_out="$3"
  local code
  code="$(curl -sS -o "$body_out" -D "$headers_out" -w "%{http_code}" "$url")"
  echo "$code"
}

http_post_json() {
  local url="$1"
  local payload="$2"
  local body_out="$3"
  local code
  code="$(curl -sS -o "$body_out" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d "$payload" \
    "$url")"
  echo "$code"
}

echo "[stage16-runtime] build art-core"
cargo build -p art-core >/dev/null

CFG="$TMP_DIR/core-global.toml"
LOG="$TMP_DIR/core.log"
write_config_global "$CFG"

echo "[stage16-runtime] start core"
CORE_CONFIG_PATH="$CFG" CORE_PORT="$PORT" "$BIN" >"$LOG" 2>&1 &
PID="$!"
wait_http_ok "http://127.0.0.1:${PORT}/health"

echo "[stage16-runtime] check / bootstrap contract"
ROOT_BODY="$TMP_DIR/root.html"
ROOT_HEADERS="$TMP_DIR/root.headers"
ROOT_CODE="$(http_get "http://127.0.0.1:${PORT}/" "$ROOT_BODY" "$ROOT_HEADERS")"
[[ "$ROOT_CODE" == "200" ]]
grep -qi "^content-type: text/html" "$ROOT_HEADERS"
grep -q 'const BOOT_TIMEOUT_MS = 5000;' "$ROOT_BODY"
grep -q 'const EVENT_KIND = "observability_gap.console_boot_failed";' "$ROOT_BODY"
grep -q 'const CONSOLE_BASE_PATH = "/console";' "$ROOT_BODY"
grep -q "Ctrl+Shift+P" "$ROOT_BODY"

echo "[stage16-runtime] check panel0 routes + content-type"
PANEL0_BODY=""
PANEL0_HEADERS=""
PANEL0_JS_BODY=""
PANEL0_JS_HEADERS=""
PANEL0_CSS_HEADERS=""
PANEL0_SW_BODY=""
PANEL0_SW_HEADERS=""
PANEL0_FAVICON_HEADERS=""
for path in /panel0 /panel0/ /panel0/index.html /panel0/panel0.js /panel0/panel0.css /panel0/panel0_sw.js /panel0/favicon.ico; do
  body="$TMP_DIR$(echo "$path" | tr '/' '_').body"
  headers="$TMP_DIR$(echo "$path" | tr '/' '_').headers"
  code="$(http_get "http://127.0.0.1:${PORT}${path}" "$body" "$headers")"
  [[ "$code" == "200" ]] || {
    echo "route failed: ${path}, code=${code}"
    exit 1
  }
  case "$path" in
    /panel0)
      PANEL0_BODY="$body"
      PANEL0_HEADERS="$headers"
      ;;
    /panel0/panel0.js)
      PANEL0_JS_BODY="$body"
      PANEL0_JS_HEADERS="$headers"
      ;;
    /panel0/panel0.css)
      PANEL0_CSS_HEADERS="$headers"
      ;;
    /panel0/panel0_sw.js)
      PANEL0_SW_BODY="$body"
      PANEL0_SW_HEADERS="$headers"
      ;;
    /panel0/favicon.ico)
      PANEL0_FAVICON_HEADERS="$headers"
      ;;
  esac
done

grep -qi "^content-type: text/html" "$PANEL0_HEADERS"
grep -qi "^content-type: application/javascript" "$PANEL0_JS_HEADERS"
grep -qi "^content-type: text/css" "$PANEL0_CSS_HEADERS"
grep -qi "^content-type: application/javascript" "$PANEL0_SW_HEADERS"
grep -qi "^content-type: image/x-icon" "$PANEL0_FAVICON_HEADERS"

grep -q 'const PANEL0_BUILD_ID = "dev";' "$PANEL0_JS_BODY"
grep -q 'const CACHE_NAME = "panel0-cache-dev";' "$PANEL0_SW_BODY"
if grep -q "__PANEL0_BUILD_ID__" "$PANEL0_JS_BODY"; then
  echo "panel0.js placeholder was not replaced"
  exit 1
fi

echo "[stage16-runtime] check snapshot/stream for console_boot_failed event contract"
INGEST_RESP="$TMP_DIR/ingest.json"
EVENT_PAYLOAD='{"events":[{"severity":"error","kind":"observability_gap.console_boot_failed","trace_id":"trace-stage16-runtime","msg":"Console bootstrap failed, switched to Panel0","details":{"reason_type":"timeout","url":"/console","http_status":null,"error_text":"console did not become available within timeout","timeout_ms":5000,"build_id":"dev","effective_profile_id":"global","trace_id":"trace-stage16-runtime"},"action_ref":"docs/runbooks/console_boot_failed.md"}]}'
INGEST_CODE="$(http_post_json "http://127.0.0.1:${PORT}/api/v1/ingest" "$EVENT_PAYLOAD" "$INGEST_RESP")"
[[ "$INGEST_CODE" == "200" ]]

SNAPSHOT="$TMP_DIR/snapshot.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$SNAPSHOT"
python3 - "$SNAPSHOT" <<'PY'
import json, pathlib, sys
snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
events = snapshot.get("events", [])
target = None
for item in events:
    event = item.get("event", {})
    if event.get("kind") == "observability_gap.console_boot_failed":
        target = event
        break
assert target is not None, events
details = target.get("details", {})
required = [
    "reason_type",
    "url",
    "http_status",
    "error_text",
    "timeout_ms",
    "build_id",
    "effective_profile_id",
    "trace_id",
]
for key in required:
    assert key in details, (key, details)
assert details["reason_type"] in ("network_error", "http_error", "timeout", "runtime_crash"), details
assert details["build_id"] == "dev", details
PY

STREAM="$TMP_DIR/stream.txt"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/stream" -H "last-event-id: 0" >"$STREAM"
grep -q "observability_gap.console_boot_failed" "$STREAM"

echo "[stage16-runtime] check core-down placeholder contract markers"
grep -q 'const health = await fetchJson("/health");' "$PANEL0_JS_BODY"
grep -q 'const snapshot = await fetchJson("/api/v1/snapshot");' "$PANEL0_JS_BODY"
grep -q "Core недоступен" "$PANEL0_BODY"

echo "[stage16-runtime] OK"
