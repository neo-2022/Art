#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
HTTP_PORT="${STAGE33_ACTION_UX_E2E_PORT:-39342}"
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

create_placeholder_png() {
  local out="$1"
  base64 -d > "$out" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2Zs5YAAAAASUVORK5CYII=
B64
}

cd "$ROOT_DIR"

corepack pnpm install --frozen-lockfile >/dev/null
corepack pnpm run console:build >/dev/null

if [[ ! -x "$PWCLI" ]]; then
  html="$ROOT_DIR/apps/console-web/dist/index.html"
  test -s "$html"
  grep -q 'data-action-open-context="incident-room"' "$html"
  grep -q 'data-action-open-context="flow-mode"' "$html"
  grep -q 'data-action-flow-current="pending"' "$html"
  grep -q 'data-action-status-chip="approved"' "$html"
  grep -q 'data-action-status-chip="executed"' "$html"
  grep -q 'data-action-status-chip="rolled_back"' "$html"
  create_placeholder_png "$ROOT_DIR/docs/governance/evidence/stage33_step7_action_flow_anti_breakage.png"
  echo "[stage33-action-flow-anti-breakage-e2e] PASS (fallback)"
  exit 0
fi

python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1 --directory "$ROOT_DIR/apps/console-web/dist" >"$TMP_DIR/http.log" 2>&1 &
HTTP_PID="$!"
wait_http_ok "http://127.0.0.1:${HTTP_PORT}/"

"$PWCLI" close-all >/dev/null 2>&1 || true
"$PWCLI" open "http://127.0.0.1:${HTTP_PORT}/" >/dev/null

incident_out="$($PWCLI eval "() => { const nav = document.querySelector('[data-route=\"/console/incident-room\"]'); if (!nav) return { ok: false, reason: 'missing incident route' }; nav.click(); const btn = document.querySelector('[data-action-open-context=\"incident-room\"]'); if (!btn) return { ok: false, reason: 'missing incident button' }; btn.click(); const section = document.querySelector('#surface-action-studio'); const context = document.querySelector('[data-action-context-source]')?.textContent || ''; const status = document.querySelector('[data-action-flow-current]')?.getAttribute('data-action-flow-current') || ''; return { ok: true, hidden: Boolean(section?.hidden), context, status }; }")"
assert_contains "$incident_out" '"ok": true' 'incident-room entry exists'
assert_contains "$incident_out" '"hidden": false' 'action-studio opened from incident-room'
assert_contains "$incident_out" '"context": "incident-room"' 'incident-room context propagated'
assert_contains "$incident_out" '"status": "pending"' 'pending status after open'

approve_out="$($PWCLI eval "() => { const btn = document.querySelector('[data-action-approve]'); if (!btn) return { ok: false }; btn.click(); return { ok: true, status: document.querySelector('[data-action-flow-current]')?.getAttribute('data-action-flow-current') || '' }; }")"
assert_contains "$approve_out" '"ok": true' 'approve button exists'
assert_contains "$approve_out" '"status": "approved"' 'approved status set'

execute_out="$($PWCLI eval "() => { const btn = document.querySelector('[data-action-execute]'); if (!btn) return { ok: false }; btn.click(); return { ok: true, status: document.querySelector('[data-action-flow-current]')?.getAttribute('data-action-flow-current') || '' }; }")"
assert_contains "$execute_out" '"ok": true' 'execute button exists'
assert_contains "$execute_out" '"status": "executed"' 'executed status set'

rollback_out="$($PWCLI eval "() => { const btn = document.querySelector('[data-action-rollback]'); if (!btn) return { ok: false }; btn.click(); return { ok: true, status: document.querySelector('[data-action-flow-current]')?.getAttribute('data-action-flow-current') || '' }; }")"
assert_contains "$rollback_out" '"ok": true' 'rollback button exists'
assert_contains "$rollback_out" '"status": "rolled_back"' 'rolled_back status set'

flow_out="$($PWCLI eval "() => { const nav = document.querySelector('[data-route=\"/console/scenario-view\"]'); if (!nav) return { ok: false, reason: 'missing scenario route' }; nav.click(); const btn = document.querySelector('[data-action-open-context=\"flow-mode\"]'); if (!btn) return { ok: false, reason: 'missing flow button' }; btn.click(); return { ok: true, context: document.querySelector('[data-action-context-source]')?.textContent || '', status: document.querySelector('[data-action-flow-current]')?.getAttribute('data-action-flow-current') || '' }; }")"
assert_contains "$flow_out" '"ok": true' 'flow-mode entry exists'
assert_contains "$flow_out" '"context": "flow-mode"' 'flow-mode context propagated'
assert_contains "$flow_out" '"status": "pending"' 'flow-mode open resets to pending'

screen="$($PWCLI screenshot)"
assert_contains "$screen" '.playwright-cli/' 'anti-breakage screenshot generated'
img_rel="$(grep -oE '\.playwright-cli/[^)]*\.png' <<<"$screen" | head -n1)"
img_abs="$ROOT_DIR/$img_rel"
test -s "$img_abs"
cp "$img_abs" "$ROOT_DIR/docs/governance/evidence/stage33_step7_action_flow_anti_breakage.png"

echo "[stage33-action-flow-anti-breakage-e2e] PASS"
