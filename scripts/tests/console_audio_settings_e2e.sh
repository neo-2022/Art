#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
HTTP_PORT="${CONSOLE_AUDIO_E2E_PORT:-39330}"
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

echo "[console-audio-e2e] install workspace"
corepack pnpm install --frozen-lockfile >/dev/null

echo "[console-audio-e2e] build console"
corepack pnpm run console:build >/dev/null

echo "[console-audio-e2e] serve dist"
python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1 --directory "$ROOT_DIR/apps/console-web/dist" >"$TMP_DIR/http.log" 2>&1 &
HTTP_PID="$!"
wait_http_ok "http://127.0.0.1:${HTTP_PORT}/"

"$PWCLI" close-all >/dev/null 2>&1 || true
out="$("$PWCLI" open "http://127.0.0.1:${HTTP_PORT}/")"
assert_contains "$out" "Page URL: http://127.0.0.1:${HTTP_PORT}/" "open console page"

out="$("$PWCLI" eval '() => ({ has_search: !!document.querySelector("[data-settings-search]"), groups: [...document.querySelectorAll("[data-settings-group]")].map((n) => n.getAttribute("data-settings-group")), effects: [...document.querySelectorAll("[data-audio-preview]")].map((n) => n.getAttribute("data-audio-preview")) })')"
assert_contains "$out" '"has_search": true' "settings search exists"
assert_contains "$out" '"visual"' "visual group exists"
assert_contains "$out" '"audio"' "audio group exists"
assert_contains "$out" '"action_success"' "audio effect action_success exists"
assert_contains "$out" '"alert_error"' "audio effect alert_error exists"

out="$("$PWCLI" eval '() => { const search = document.querySelector("[data-settings-search]"); const items = [...document.querySelectorAll("[data-setting-item]")]; const total = items.length; search.value = "warning"; search.dispatchEvent(new Event("input", { bubbles: true })); const visible = items.filter((n) => !n.hidden).length; return { total, visible, filtered: visible < total && visible > 0 }; }')"
assert_contains "$out" '"filtered": true' "search filters settings"

out="$("$PWCLI" eval '() => { const btn = document.querySelector("[data-audio-preview=\"action_success\"]"); btn.click(); return { clicked: true, audioEnabled: document.querySelector("[data-design-control=\"audioEnabled\"]").checked }; }')"
assert_contains "$out" '"clicked": true' "preview click"
assert_contains "$out" '"audioEnabled": true' "audio enabled by default"

out="$("$PWCLI" eval '() => { const raw = JSON.stringify({ ...JSON.parse(localStorage.getItem("art.console.design.v0_2") || "{}"), audioCustomByEffect: { ui_click: "data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAESsAACJWAAACABAAZGF0YQAAAAA=" } }); localStorage.setItem("art.console.design.v0_2", raw); return { seeded: true }; }')"
assert_contains "$out" '"seeded": true' "seed custom effect"

"$PWCLI" reload >/dev/null
out="$("$PWCLI" eval '() => ({ status: document.querySelector("[data-audio-custom-status=\"ui_click\"]")?.textContent || "", hasCustom: (document.querySelector("[data-audio-custom-status=\"ui_click\"]")?.textContent || "").toLowerCase().includes("custom") })')"
assert_contains "$out" '"hasCustom": true' "custom status after reload"

out="$("$PWCLI" eval '() => { const clear = document.querySelector("[data-audio-clear=\"ui_click\"]"); clear.click(); const raw = localStorage.getItem("art.console.design.v0_2") || "{}"; const parsed = JSON.parse(raw); const hasCustom = !!(parsed.audioCustomByEffect && parsed.audioCustomByEffect.ui_click); return { cleared: !hasCustom }; }')"
assert_contains "$out" '"cleared": true' "clear custom effect"

out="$("$PWCLI" eval '() => { const name = document.querySelector("[data-profile-name]"); name.value = "night-shift"; document.querySelector("[data-profile-save]").click(); const select = document.querySelector("[data-profile-select]"); const options = [...select.options].map((o) => o.value); return { saved: options.includes("night-shift") }; }')"
assert_contains "$out" '"saved": true' "profile save"

out="$("$PWCLI" eval '() => { const select = document.querySelector("[data-profile-select]"); select.value = "night-shift"; document.querySelector("[data-profile-apply]").click(); const status = document.querySelector("[data-profile-status]")?.textContent || ""; return { applied: status.toLowerCase().includes("applied") || status.toLowerCase().includes("примен") }; }')"
assert_contains "$out" '"applied": true' "profile apply"

out="$("$PWCLI" eval '() => { document.querySelector("[data-profile-export]").click(); const status = document.querySelector("[data-profile-status]")?.textContent || ""; return { exported: status.toLowerCase().includes("export") || status.toLowerCase().includes("экспорт") }; }')"
assert_contains "$out" '"exported": true' "profile export"

out="$("$PWCLI" eval 'async () => { const input = document.querySelector("[data-profile-import-file]"); const payload = JSON.stringify({ name: "imported-profile", settings: { globalBrightness: 111, audioEnabled: true } }); const file = new File([payload], "imported-profile.json", { type: "application/json" }); const dt = new DataTransfer(); dt.items.add(file); input.files = dt.files; input.dispatchEvent(new Event("change", { bubbles: true })); await new Promise((resolve) => setTimeout(resolve, 300)); const select = document.querySelector("[data-profile-select]"); const options = [...select.options].map((o) => o.value); return { imported: options.includes("imported-profile") }; }')"
assert_contains "$out" '"imported": true' "profile import"

out="$("$PWCLI" eval '() => { const select = document.querySelector("[data-profile-select]"); select.value = "night-shift"; document.querySelector("[data-profile-delete]").click(); const options = [...select.options].map((o) => o.value); return { deleted: !options.includes("night-shift") }; }')"
assert_contains "$out" '"deleted": true' "profile delete"

out="$("$PWCLI" eval '() => { localStorage.setItem("art.console.settings.policy_locks.v0_2", JSON.stringify({ fontScale: true })); return { seededLocks: true }; }')"
assert_contains "$out" '"seededLocks": true' "seed policy locks"
"$PWCLI" reload >/dev/null
out="$("$PWCLI" eval '() => ({ locked: document.querySelector("[data-design-control=\"fontScale\"]")?.disabled === true, hasBadge: !!document.querySelector(".policy-lock-badge") })')"
assert_contains "$out" '"locked": true' "policy lock disables control"
assert_contains "$out" '"hasBadge": true' "policy lock badge present"

echo "[console-audio-e2e] all scenarios passed"
