#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# schema-level truth-mode contract checks
for f in \
  docs/contracts/v2/schemas/claim_v2.json \
  docs/contracts/v2/schemas/dialog_message_v2.json \
  docs/contracts/v2/schemas/snapshot_v2.json; do
  test -s "$f"
  grep -q '"truth_mode"' "$f"
  grep -q '"observed"' "$f"
  grep -q '"derived"' "$f"
  grep -q '"predicted"' "$f"
  grep -q '"evidence_refs"' "$f"
done

# runtime/ui-law checks for observed-without-evidence rejection
corepack pnpm --filter @art/ui-laws run test

echo "stage30 truth-modes tests: OK"
