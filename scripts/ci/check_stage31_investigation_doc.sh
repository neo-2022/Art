#!/usr/bin/env bash
set -euo pipefail

test -s "docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md"
test -s "docs/source/investigations_as_code.md"
test -s "docs/runbooks/investigation_replay_failed.md"

grep -q "stage31-investigation-doc-tests" docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md
grep -q "observability_gap.investigation_replay_failed" docs/governance/observability_gap_registry.md

# Runtime integration suite (core + console foundation)
cargo test -p art-core v2_ingest_snapshot_stream_integration
cargo test -p art-core v2_dna_clusters_and_similar_lookup
corepack pnpm --filter ./apps/console-web run test

echo "stage31 investigation doc gate: OK"
