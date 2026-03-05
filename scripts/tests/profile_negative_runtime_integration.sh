#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT_DIR/target/debug/art-core"
TMP_DIR="$(mktemp -d)"
PORT=37072
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
  for _ in $(seq 1 60); do
    if curl -sf "$url" >/dev/null; then
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

post_json() {
  local url="$1"
  local payload="$2"
  local output="$3"
  local code
  code="$(curl -sS -o "$output" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d "$payload" \
    "$url")"
  echo "$code"
}

echo "[stage03-negative] build art-core binary"
cargo build -p art-core >/dev/null

CFG="$TMP_DIR/core-global.toml"
LOG="$TMP_DIR/core.log"
RESP1="$TMP_DIR/resp1.json"
RESP2="$TMP_DIR/resp2.json"

write_config_global "$CFG"

echo "[stage03-negative] start core"
CORE_CONFIG_PATH="$CFG" CORE_PORT="$PORT" "$BIN" >"$LOG" 2>&1 &
PID="$!"
wait_http_ok "http://127.0.0.1:${PORT}/health"

echo "[stage03-negative] invalid profile_id must fail with profile_violation"
CODE1="$(post_json "http://127.0.0.1:${PORT}/api/v1/profile/apply" \
  '{"profile_id":"moon","retention_days":30,"export_mode":"standard","egress_policy":"controlled","residency":"any","updates_mode":"online"}' \
  "$RESP1")"
if [[ "$CODE1" != "400" ]]; then
  echo "expected 400, got $CODE1"
  exit 1
fi
python3 - "$RESP1" <<'PY'
import json, pathlib, sys
obj = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj.get("error") == "profile_violation", obj
PY

echo "[stage03-negative] invalid guardrail values must fail with profile_violation"
CODE2="$(post_json "http://127.0.0.1:${PORT}/api/v1/profile/apply" \
  '{"profile_id":"airgapped","retention_days":30,"export_mode":"offline-only","egress_policy":"controlled","residency":"local-only","updates_mode":"manual-offline"}' \
  "$RESP2")"
if [[ "$CODE2" != "400" ]]; then
  echo "expected 400, got $CODE2"
  exit 1
fi
python3 - "$RESP2" <<'PY'
import json, pathlib, sys
obj = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert obj.get("error") == "profile_violation", obj
PY

echo "[stage03-negative] snapshot must contain observability_gap.profile_violation with evidence"
curl -sf "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$TMP_DIR/snapshot.json"
python3 - "$TMP_DIR/snapshot.json" <<'PY'
import json, pathlib, sys
snapshot = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
events = snapshot.get("events", [])
violations = [e for e in events if e.get("event", {}).get("kind") == "observability_gap.profile_violation"]
assert len(violations) >= 2, violations
for v in violations:
    ev = v.get("event", {})
    assert ev.get("violated_rule"), ev
    assert ev.get("parameter"), ev
    current_values = ev.get("current_values", {})
    assert current_values.get("current"), ev
    assert current_values.get("expected"), ev
PY

echo "[stage03-negative] incidents endpoint must include profile_violation"
curl -sf "http://127.0.0.1:${PORT}/api/v1/incidents" >"$TMP_DIR/incidents.json"
python3 - "$TMP_DIR/incidents.json" <<'PY'
import json, pathlib, sys
obj = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
items = obj.get("items", [])
assert any(i.get("kind") == "profile_violation" and i.get("severity") == "SEV2" for i in items), items
PY

echo "[stage03-negative] profile negative runtime integration: OK"
