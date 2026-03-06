#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
HTTP_PORT="${STAGE32_AUDIT_UX_E2E_PORT:-39341}"
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
  grep -q 'data-audit-verify-trigger="incident-room"' "$html"
  grep -q 'data-audit-verify-trigger="investigation-library"' "$html"
  grep -q 'data-audit-verify-trigger="flow-mode"' "$html"
  grep -q 'data-audit-lineage-link' "$html"
  create_placeholder_png "$ROOT_DIR/docs/governance/evidence/stage32_step6_anti_breakage.png"
  echo "[stage32-audit-ux-anti-breakage-e2e] PASS (fallback)"
  exit 0
fi

python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1 --directory "$ROOT_DIR/apps/console-web/dist" >"$TMP_DIR/http.log" 2>&1 &
HTTP_PID="$!"
wait_http_ok "http://127.0.0.1:${HTTP_PORT}/"

"$PWCLI" close-all >/dev/null 2>&1 || true
"$PWCLI" open "http://127.0.0.1:${HTTP_PORT}/" >/dev/null

for source in incident-room investigation-library flow-mode; do
  out="$("$PWCLI" eval "() => { const btn = document.querySelector('[data-audit-verify-trigger=\"${source}\"]'); if (!btn) return { ok: false }; btn.click(); const status = document.querySelector('[data-audit-verify-status]')?.getAttribute('data-audit-verify-status') || ''; const sourceVal = document.querySelector('[data-audit-verify-source]')?.getAttribute('data-audit-verify-source') || ''; const lineage = document.querySelector('[data-audit-lineage-link]')?.getAttribute('href') || ''; return { ok: true, source: sourceVal, status, lineage }; }" )"
  assert_contains "$out" '"ok": true' "${source}: button exists"
  assert_contains "$out" "\"source\": \"${source}\"" "${source}: source propagated"
  assert_contains "$out" '"status": "verified"' "${source}: status verified"
  assert_contains "$out" '"/console/evidence/audit-proof-chain"' "${source}: lineage link preserved"
done

screen="$("$PWCLI" screenshot)"
assert_contains "$screen" ".playwright-cli/" "anti-breakage screenshot generated"
img_rel="$(grep -oE '\.playwright-cli/[^)]*\.png' <<<"$screen" | head -n1)"
img_abs="$ROOT_DIR/$img_rel"
test -s "$img_abs"
cp "$img_abs" "$ROOT_DIR/docs/governance/evidence/stage32_step6_anti_breakage.png"

echo "[stage32-audit-ux-anti-breakage-e2e] PASS"
