#!/usr/bin/env bash
set -euo pipefail

corepack pnpm --filter @art/local-stores run build

node --test packages/local-stores/test/flow-inspectability.test.mjs | tee docs/governance/evidence/stage35_flow_snapshot_replay_ci.log

grep -q "flow snapshot replay: serialize/restore keeps positions and visibility" docs/governance/evidence/stage35_flow_snapshot_replay_ci.log

echo "stage35 flow snapshot replay gate: OK"
