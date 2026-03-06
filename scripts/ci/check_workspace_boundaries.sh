#!/usr/bin/env bash
set -euo pipefail

violations=0

# Browser must not depend on Console app surface.
if rg -n "from ['\"](@art/console-web|apps/|\.\./\.\./apps/)" browser/src browser/test >/dev/null; then
  count="$(rg -n "from ['\"](@art/console-web|apps/|\.\./\.\./apps/)" browser/src browser/test | wc -l | tr -d ' ')"
  violations=$((violations + count))
  echo "workspace boundary violation: browser imports console app"
  rg -n "from ['\"](@art/console-web|apps/|\.\./\.\./apps/)" browser/src browser/test || true
fi

# Console app must not import core/agent/browser directly.
if rg -n "from ['\"][^'\"]*(core/|agent/|browser/)" apps/console-web/src >/dev/null; then
  count="$(rg -n "from ['\"][^'\"]*(core/|agent/|browser/)" apps/console-web/src | wc -l | tr -d ' ')"
  violations=$((violations + count))
  echo "workspace boundary violation: console imports core/agent/browser directly"
  rg -n "from ['\"][^'\"]*(core/|agent/|browser/)" apps/console-web/src || true
fi

# Console app should use @art/* package imports for shared modules.
if rg -n "from ['\"]\.\./\.\./packages/" apps/console-web/src >/dev/null; then
  count="$(rg -n "from ['\"]\.\./\.\./packages/" apps/console-web/src | wc -l | tr -d ' ')"
  violations=$((violations + count))
  echo "workspace boundary violation: console uses direct relative imports into packages"
  rg -n "from ['\"]\.\./\.\./packages/" apps/console-web/src || true
fi

echo "forbidden_import_count=${violations}"
if [[ "$violations" -gt 0 ]]; then
  exit 1
fi

echo "workspace boundary check: OK"
