#!/usr/bin/env bash
set -euo pipefail

test -s "packages/local-stores/src/index.ts"
test -s "packages/local-stores/test/local-stores.test.mjs"
test -s "apps/console-web/src/main.ts"
test -s "apps/console-web/test/console-web.test.mjs"

corepack pnpm --filter @art/local-stores run test
corepack pnpm --filter @art/console-web run test

echo "stage31 investigation library gate: OK"
