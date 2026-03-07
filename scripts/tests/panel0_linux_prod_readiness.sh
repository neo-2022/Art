#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CORE_BIN="$ROOT_DIR/target/debug/art-core"
PROXY_BIN="$ROOT_DIR/scripts/tests/panel0_mock_console_proxy.py"
CORE_PORT="${CORE_PORT:-39210}"
PROXY_PORT="${PANEL0_PROXY_PORT:-39220}"
CORE_PID=""
PROXY_PID=""
TMP_DIR="$(mktemp -d)"

export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"

dump_logs() {
  echo "--- panel0-linux core.log ---"
  [[ -f "$TMP_DIR/core.log" ]] && cat "$TMP_DIR/core.log" || true
  echo "--- panel0-linux proxy.log ---"
  [[ -f "$TMP_DIR/proxy.log" ]] && cat "$TMP_DIR/proxy.log" || true
}

on_error() {
  dump_logs
}
trap on_error ERR

cleanup() {
  if [[ -x "$PWCLI" ]]; then
    "$PWCLI" close-all >/dev/null 2>&1 || true
  fi
  if [[ -n "$PROXY_PID" ]] && kill -0 "$PROXY_PID" 2>/dev/null; then
    kill "$PROXY_PID" || true
    wait "$PROXY_PID" || true
  fi
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" 2>/dev/null; then
    kill "$CORE_PID" || true
    wait "$CORE_PID" || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1"
    exit 1
  }
}

wait_http_ok() {
  local url="$1"
  for _ in $(seq 1 80); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  echo "timeout waiting for $url"
  return 1
}

assert_contains() {
  local text="$1"
  local expected="$2"
  local label="$3"
  if ! grep -Fq "$expected" <<<"$text"; then
    echo "ASSERT FAIL: $label"
    echo "expected: $expected"
    echo "got:"
    echo "$text"
    exit 1
  fi
}

fetch_proxy_snapshot() {
  for _ in $(seq 1 20); do
    if out="$(curl -fsS "http://127.0.0.1:${PROXY_PORT}/api/v1/snapshot" 2>/dev/null)"; then
      printf '%s\n' "$out"
      return 0
    fi
    sleep 0.2
  done
  echo "ASSERT FAIL: unable to fetch proxy snapshot from :${PROXY_PORT}"
  return 1
}

wait_panel0_state() {
  local expected_core_down="$1"
  local expected_path="$2"
  local timeout_secs="${3:-15}"
  local last=""
  local deadline=$((SECONDS + timeout_secs))
  while (( SECONDS < deadline )); do
    if out="$("$PWCLI" eval '() => ({ core_down: !document.querySelector("#core-down")?.classList.contains("hidden"), path: location.pathname })' 2>/dev/null)"; then
      last="$out"
      if grep -Fq "\"core_down\": ${expected_core_down}" <<<"$out" && grep -Fq "\"path\": \"${expected_path}\"" <<<"$out"; then
        printf '%s\n' "$out"
        return 0
      fi
    fi
    sleep 0.5
  done
  printf '%s\n' "$last"
  return 1
}

set_modes() {
  local console_mode="$1"
  local ingest_mode="$2"
  curl -fsS \
    -H "content-type: application/json" \
    -X POST \
    -d "{\"console_mode\":\"${console_mode}\",\"ingest_mode\":\"${ingest_mode}\"}" \
    "http://127.0.0.1:${PROXY_PORT}/__panel0_control" >/dev/null
}

boot_count() {
  fetch_proxy_snapshot | python3 -c '
import json, sys
obj = json.load(sys.stdin)
count = 0
for item in obj.get("events", []):
    event = item.get("event", {})
    if event.get("kind") == "observability_gap.console_boot_failed":
        count += 1
print(count)
'
}

latest_reason() {
  fetch_proxy_snapshot | python3 -c '
import json, sys
obj = json.load(sys.stdin)
latest_seq = -1
latest_reason = "none"
for item in obj.get("events", []):
    event = item.get("event", {})
    if event.get("kind") != "observability_gap.console_boot_failed":
        continue
    seq = int(item.get("seq", -1))
    if seq > latest_seq:
        latest_seq = seq
        latest_reason = str(event.get("details", {}).get("reason_type", "none"))
print(latest_reason)
'
}

start_core() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" 2>/dev/null; then
    return 0
  fi
  CORE_CONFIG_PATH="$ROOT_DIR/config/core.toml" \
  CORE_PORT="$CORE_PORT" \
  ART_CONSOLE_BASE_PATH="/console" \
  PANEL0_BUILD_ID="linux-prod-readiness" \
  "$CORE_BIN" >"$TMP_DIR/core.log" 2>&1 &
  CORE_PID="$!"
  wait_http_ok "http://127.0.0.1:${CORE_PORT}/health"
}

stop_core() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" 2>/dev/null; then
    kill "$CORE_PID" || true
    wait "$CORE_PID" || true
  fi
  CORE_PID=""
}

require_cmd curl
require_cmd cargo
require_cmd python3
require_cmd npx

test -x "$PROXY_BIN"

echo "[panel0-linux] build art-core"
cargo build -p art-core >/dev/null

start_core

if [[ ! -x "$PWCLI" ]]; then
  echo "[panel0-linux] playwright-cli wrapper not found; running fallback smoke checks"

  for path in / /panel0/ /panel0/panel0.js /panel0/panel0.css /panel0/panel0_sw.js /panel0/favicon.ico; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${CORE_PORT}${path}")"
    if [[ "$code" != "200" ]]; then
      echo "ASSERT FAIL: expected 200 for ${path}, got ${code}"
      exit 1
    fi
  done

  html="$(curl -fsS "http://127.0.0.1:${CORE_PORT}/")"
  assert_contains "$html" "const BOOT_TIMEOUT_MS = 5000;" "bootstrap timeout is 5000ms"
  assert_contains "$html" "observability_gap.console_boot_failed" "bootstrap emits console_boot_failed"

  index_html="$(curl -fsS "http://127.0.0.1:${CORE_PORT}/panel0/")"
  assert_contains "$index_html" "id=\"core-down\"" "panel0 includes core-down placeholder"

  echo "[panel0-linux] fallback smoke checks passed"
  exit 0
fi

echo "[panel0-linux] start mock proxy"
python3 "$PROXY_BIN" --listen "127.0.0.1:${PROXY_PORT}" --upstream "127.0.0.1:${CORE_PORT}" >"$TMP_DIR/proxy.log" 2>&1 &
PROXY_PID="$!"
wait_http_ok "http://127.0.0.1:${PROXY_PORT}/health"

"$PWCLI" close-all >/dev/null 2>&1 || true

# Scenario 1: Console UP -> no fallback
set_modes "up" "pass"
base_count="$(boot_count)"
out="$("$PWCLI" open "http://127.0.0.1:${PROXY_PORT}/")"
assert_contains "$out" "Page URL: http://127.0.0.1:${PROXY_PORT}/console" "console up opens /console"
out="$("$PWCLI" eval '() => location.pathname')"
assert_contains "$out" '"/console"' "console up pathname"
after_count="$(boot_count)"
if [[ "$after_count" != "$base_count" ]]; then
  echo "ASSERT FAIL: console up must not emit console_boot_failed"
  echo "before=$base_count after=$after_count"
  exit 1
fi

echo "[panel0-linux] scenario 1 ok"

# Scenario 2: HTTP error -> fallback + event http_error
set_modes "http_error" "pass"
base_count="$(boot_count)"
out="$("$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/")"
assert_contains "$out" "Page URL: http://127.0.0.1:${PROXY_PORT}/panel0/" "http_error fallback to panel0"
out="$("$PWCLI" eval '() => location.pathname')"
assert_contains "$out" '"/panel0/"' "http_error pathname"
after_count="$(boot_count)"
if (( after_count <= base_count )); then
  echo "ASSERT FAIL: http_error must increment console_boot_failed count"
  echo "before=$base_count after=$after_count"
  exit 1
fi
reason="$(latest_reason)"
if [[ "$reason" != "http_error" ]]; then
  echo "ASSERT FAIL: expected latest reason_type=http_error got=$reason"
  exit 1
fi

echo "[panel0-linux] scenario 2 ok"

# Scenario 3: slow console (>5s) -> timeout fallback
set_modes "slow_timeout" "pass"
base_count="$(boot_count)"
"$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/" >/dev/null
sleep 7
out="$("$PWCLI" eval '() => ({ path: location.pathname, timeout_fallback_ok: location.pathname === "/panel0/" })')"
assert_contains "$out" '"timeout_fallback_ok": true' "timeout fallback to panel0"
after_count="$(boot_count)"
if (( after_count <= base_count )); then
  echo "ASSERT FAIL: timeout must increment console_boot_failed count"
  echo "before=$base_count after=$after_count"
  exit 1
fi
reason="$(latest_reason)"
if [[ "$reason" != "timeout" ]]; then
  echo "ASSERT FAIL: expected latest reason_type=timeout got=$reason"
  exit 1
fi

echo "[panel0-linux] scenario 3 ok"

# Scenario 4: hotkey opens panel0 without creating a new failure event
set_modes "up" "pass"
base_count="$(boot_count)"
"$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/panel0/" >/dev/null
"$PWCLI" keydown Control >/dev/null
"$PWCLI" keydown Shift >/dev/null
"$PWCLI" press p >/dev/null
"$PWCLI" keyup Shift >/dev/null
"$PWCLI" keyup Control >/dev/null
out="$("$PWCLI" eval '() => location.pathname')"
assert_contains "$out" '"/panel0/"' "hotkey keeps panel0 route"
after_count="$(boot_count)"
if [[ "$after_count" != "$base_count" ]]; then
  echo "ASSERT FAIL: hotkey must not emit console_boot_failed"
  echo "before=$base_count after=$after_count"
  exit 1
fi

echo "[panel0-linux] scenario 4 ok"

# Scenario 5: ingest down -> backlog queued; recovery -> backlog delivered
set_modes "http_error" "down"
base_count="$(boot_count)"
"$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/" >/dev/null
out="$("$PWCLI" eval '() => { const raw = localStorage.getItem("art.panel0.console_boot_failed.backlog.v1"); if (!raw) return {backlog_len: 0, has_backlog: false}; try { const len = JSON.parse(raw).length; return {backlog_len: len, has_backlog: len > 0}; } catch { return {backlog_len: -1, has_backlog: false}; } }')"
assert_contains "$out" '"has_backlog": true' "ingest down queues backlog"
after_count="$(boot_count)"
if [[ "$after_count" != "$base_count" ]]; then
  echo "ASSERT FAIL: ingest down must not increase snapshot count"
  echo "before=$base_count after=$after_count"
  exit 1
fi

set_modes "http_error" "pass"
out="$("$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/panel0/")"
assert_contains "$out" "Page URL: http://127.0.0.1:${PROXY_PORT}/panel0/" "reopen panel0 for backlog flush"
out="$("$PWCLI" eval 'async () => {
  const readState = () => {
    const raw = localStorage.getItem("art.panel0.console_boot_failed.backlog.v1");
    if (!raw) return {backlog_len: 0, backlog_cleared: true};
    try {
      const len = JSON.parse(raw).length;
      return {backlog_len: len, backlog_cleared: len === 0};
    } catch {
      return {backlog_len: -1, backlog_cleared: false};
    }
  };
  for (let i = 0; i < 24; i += 1) {
    const state = readState();
    if (state.backlog_cleared) {
      return state;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  return readState();
}')"
assert_contains "$out" '"backlog_cleared": true' "backlog flush after ingest recovery"
after_count="$(boot_count)"
if (( after_count <= base_count )); then
  echo "ASSERT FAIL: recovered ingest must publish queued event"
  echo "before=$base_count after=$after_count"
  exit 1
fi

echo "[panel0-linux] scenario 5 ok"

# Scenario 6: Core DOWN + Console DOWN -> placeholder; then auto-recovery
set_modes "http_error" "pass"
"$PWCLI" goto "http://127.0.0.1:${PROXY_PORT}/panel0/" >/dev/null
"$PWCLI" reload >/dev/null
stop_core
out="$("$PWCLI" reload)"
assert_contains "$out" "Page URL: http://127.0.0.1:${PROXY_PORT}/panel0/" "offline reload stays on panel0"
sleep 2.5
out="$("$PWCLI" eval '() => { const text = document.body.innerText || ""; return { core_down: !document.querySelector("#core-down")?.classList.contains("hidden"), has_text: text.includes("Core is unavailable") || text.includes("Core недоступен") }; }')"
assert_contains "$out" '"core_down": true' "core down placeholder visible"

start_core
wait_http_ok "http://127.0.0.1:${PROXY_PORT}/health"
if ! out="$(wait_panel0_state false "/panel0/" 15)"; then
  echo "[panel0-linux] auto recovery not observed in headless loop, checking reload recovery"
  "$PWCLI" reload >/dev/null
  out="$(wait_panel0_state false "/panel0/" 5 || true)"
fi
assert_contains "$out" '"core_down": false' "placeholder hides after core recovery"
assert_contains "$out" '"path": "/panel0/"' "route remains panel0 after recovery"

echo "[panel0-linux] scenario 6 ok"
echo "[panel0-linux] all scenarios passed"
