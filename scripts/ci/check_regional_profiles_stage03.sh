#!/usr/bin/env bash
set -euo pipefail
for f in docs/compliance/profiles.md docs/compliance/data_residency.md docs/compliance/profile_guards.md docs/compliance/airgapped.md docs/compliance/test_matrix.md docs/runbooks/profile_violation.md; do
  test -s "$f"
done
grep -q "profile selection" docs/compliance/profiles.md
grep -q "profile switch procedure" docs/compliance/profiles.md
grep -q "migration/validation" docs/compliance/profiles.md
grep -q "transition matrix" docs/compliance/profiles.md
grep -q "profile_id" docs/compliance/profiles.md
grep -q "fail closed" docs/compliance/profile_guards.md
grep -q "observability_gap.profile_violation" docs/compliance/profile_guards.md
grep -q "offline packs update" docs/compliance/airgapped.md
grep -q "signature keys" docs/compliance/airgapped.md
grep -q "profile_id" docs/compliance/data_residency.md
grep -q "allowed" docs/compliance/data_residency.md
grep -q "автоматизированы" docs/compliance/test_matrix.md
grep -q "CI" docs/compliance/test_matrix.md
echo "stage03 docs gate: OK"
