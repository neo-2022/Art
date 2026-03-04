#!/usr/bin/env bash
set -euo pipefail
for f in \
  docs/core/pipeline_overview.md \
  docs/core/rules.md \
  docs/core/enrich.md \
  docs/core/fingerprint.md \
  docs/core/source_stale.md \
  docs/runbooks/pipeline_stage_failed.md \
  docs/runbooks/source_stale.md; do
  test -s "$f"
done

grep -q "template injection matrix" docs/core/enrich.md
grep -q "escape-only" docs/core/enrich.md
grep -q "sha256" docs/core/fingerprint.md
grep -q "canonical_json" docs/core/fingerprint.md
grep -q "collision" docs/core/fingerprint.md
grep -q "600000" docs/core/source_stale.md
grep -q "observability_gap.source_stale" docs/core/source_stale.md
for f in docs/runbooks/pipeline_stage_failed.md docs/runbooks/source_stale.md; do
  grep -q "mitigations" "$f"
  grep -q "verification" "$f"
done

echo "stage13 docs gate: OK"
