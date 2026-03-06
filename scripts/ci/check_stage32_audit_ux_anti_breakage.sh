#!/usr/bin/env bash
set -euo pipefail

test -s "apps/console-web/src/main.ts"
test -s "apps/console-web/test/console-web.test.mjs"
test -x "scripts/tests/stage32_audit_ux_anti_breakage_e2e.sh"

corepack pnpm --filter @art/console-web run test
bash scripts/tests/stage32_audit_ux_anti_breakage_e2e.sh

echo "stage32 audit ux anti-breakage gate: OK"
