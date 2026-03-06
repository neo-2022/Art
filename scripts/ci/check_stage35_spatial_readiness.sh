#!/usr/bin/env bash
set -euo pipefail

test -s "docs/source/checklists/CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md"
test -s "docs/source/spatial_store_v0_2.md"
test -s "docs/runbooks/spatial_index_degraded.md"

grep -q "stage35-spatial-readiness-tests" docs/source/checklists/CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
grep -q "observability_gap.spatial_index_degraded" docs/governance/observability_gap_registry.md

# Runtime integration suite (local-stores spatial adapter contracts)
corepack pnpm --filter @art/local-stores run test

echo "stage35 spatial readiness gate: OK"
