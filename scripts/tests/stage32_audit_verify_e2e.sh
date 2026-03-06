#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
HTTP_PORT="${STAGE32_AUDIT_E2E_PORT:-39340}"
HTTP_PID=""

export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"

cleanup() {
  "$PWCLI" close-all >/dev/null 2>&1 || true
  if [[ -n "$HTTP_PID" ]] && kill -0 "$HTTP_PID" 2>/dev/null; then
    kill "$HTTP_PID" || true
    wait "$HTTP_PID" || true
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

require_cmd corepack
require_cmd python3
require_cmd curl
test -x "$PWCLI"

cd "$ROOT_DIR"

corepack pnpm install --frozen-lockfile >/dev/null
corepack pnpm run console:build >/dev/null

python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1 --directory "$ROOT_DIR/apps/console-web/dist" >"$TMP_DIR/http.log" 2>&1 &
HTTP_PID="$!"
wait_http_ok "http://127.0.0.1:${HTTP_PORT}/"

"$PWCLI" close-all >/dev/null 2>&1 || true
out="$("$PWCLI" open "http://127.0.0.1:${HTTP_PORT}/")"
assert_contains "$out" "Page URL: http://127.0.0.1:${HTTP_PORT}/" "open console page"

out="$("$PWCLI" eval '() => ({ has_panel: !!document.querySelector("[data-audit-verify-panel=\"true\"]"), status: document.querySelector("[data-audit-verify-status]")?.getAttribute("data-audit-verify-status") || "", chain_steps: [...document.querySelectorAll("[data-audit-chain-step]")].map((n) => n.getAttribute("data-audit-chain-step")) })')"
assert_contains "$out" '"has_panel": true' "verify panel exists"
assert_contains "$out" '"status": "verified"' "verify status is deterministic"
assert_contains "$out" '"leaf:aud-shell-1"' "proof chain has leaf"
assert_contains "$out" '"root:sha256-chain-v1"' "proof chain has root"

screen="$("$PWCLI" screenshot)"
assert_contains "$screen" ".playwright-cli/" "screenshot generated"

img_rel="$(grep -oE '\.playwright-cli/[^)]*\.png' <<<"$screen" | head -n1)"
if [[ -z "$img_rel" ]]; then
  echo "ASSERT FAIL: screenshot path not found"
  echo "$screen"
  exit 1
fi
img_abs="$ROOT_DIR/$img_rel"
test -s "$img_abs"

cp "$img_abs" "$ROOT_DIR/docs/governance/evidence/stage32_step3_verify_ui.png"

echo "[stage32-audit-verify-e2e] PASS"
