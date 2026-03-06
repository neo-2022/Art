#!/usr/bin/env bash
set -euo pipefail

corepack pnpm --filter @art/local-stores run build

node --test packages/local-stores/test/flow-inspectability.test.mjs | tee docs/governance/evidence/stage35_flow_inspectability_ci.log

grep -q "flow inspectability: every semantic node type resolves evidence lineage" docs/governance/evidence/stage35_flow_inspectability_ci.log

echo "stage35 flow inspectability gate: OK"
