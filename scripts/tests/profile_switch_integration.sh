#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT_DIR/target/debug/art-core"
TMP_DIR="$(mktemp -d)"
PORT=37071
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

write_config_eu() {
  cat >"$1" <<'EOF'
profile_id = "eu"
retention_days = 30
export_mode = "restricted"
egress_policy = "strict"
residency = "eu-only"
updates_mode = "controlled"
EOF
}

write_config_invalid_airgapped() {
  cat >"$1" <<'EOF'
profile_id = "airgapped"
retention_days = 30
export_mode = "offline-only"
egress_policy = "controlled"
residency = "local-only"
updates_mode = "manual-offline"
EOF
}

start_core() {
  local cfg="$1"
  local log="$2"
  CORE_CONFIG_PATH="$cfg" CORE_PORT="$PORT" "$BIN" >"$log" 2>&1 &
  PID="$!"
}

stop_core() {
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    wait "$PID" || true
  fi
  PID=""
}

check_effective_profile() {
  local expected="$1"
  local body
  body="$(curl -sf "http://127.0.0.1:${PORT}/api/v1/profile/effective")"
  echo "$body" | grep -q "\"effective_profile_id\":\"${expected}\""
}

echo "[stage03] build art-core binary"
cargo build -p art-core >/dev/null

GLOBAL_CFG="$TMP_DIR/core-global.toml"
EU_CFG="$TMP_DIR/core-eu.toml"
BAD_CFG="$TMP_DIR/core-bad.toml"
LOG1="$TMP_DIR/core-global.log"
LOG2="$TMP_DIR/core-eu.log"
LOG3="$TMP_DIR/core-bad.log"

write_config_global "$GLOBAL_CFG"
write_config_eu "$EU_CFG"
write_config_invalid_airgapped "$BAD_CFG"

echo "[stage03] start core with global profile"
start_core "$GLOBAL_CFG" "$LOG1"
wait_http_ok "http://127.0.0.1:${PORT}/health"
check_effective_profile "global"

echo "[stage03] switch procedure: stop core -> apply config -> start core -> guard check"
stop_core
start_core "$EU_CFG" "$LOG2"
wait_http_ok "http://127.0.0.1:${PORT}/health"
check_effective_profile "eu"

echo "[stage03] guardrails fail closed on invalid profile config"
stop_core
start_core "$BAD_CFG" "$LOG3"
sleep 1
if kill -0 "$PID" 2>/dev/null; then
  echo "core should not stay alive with invalid profile config"
  exit 1
fi

echo "[stage03] profile switch integration: OK"
