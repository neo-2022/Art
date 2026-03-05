#!/usr/bin/env bash
set -euo pipefail
for f in docs/release/release_process.md docs/release/versioning.md docs/release/compat_matrix.md docs/release/downgrade.md docs/runbooks/release_signing_failed.md; do
  test -s "$f"
done
grep -q "manual" docs/release/release_process.md
grep -q "CI" docs/release/release_process.md
grep -q "SemVer" docs/release/release_process.md
grep -q "N-1" docs/release/downgrade.md
grep -q "инциденты читаются" docs/release/downgrade.md
grep -q "mitigations" docs/runbooks/release_signing_failed.md
grep -q "verification" docs/runbooks/release_signing_failed.md
grep -q "release_signing_failed" docs/governance/observability_gap_registry.md
echo "stage24 docs gate: OK"
