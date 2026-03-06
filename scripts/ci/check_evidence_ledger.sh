#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

filter_repo_paths() {
  if command -v rg >/dev/null 2>&1; then
    rg '^(docs/|tests/|scripts/)'
  else
    grep -E '^(docs/|tests/|scripts/)'
  fi
}

MASTER="docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md"
LEDGER="docs/governance/evidence/evidence_ledger.yaml"
RU_DOC="docs/portal/DELIVERY_EVIDENCE.md"
EN_DOC="docs/en/portal/DELIVERY_EVIDENCE.md"

for f in "$MASTER" "$LEDGER" "$RU_DOC" "$EN_DOC"; do
  test -s "$f"
done

grep -q '^version:' "$LEDGER"
grep -q '^entries:' "$LEDGER"
grep -q '^## Source of truth' "$RU_DOC"
grep -q '^## Source of truth' "$EN_DOC"

# Closed program stages (28..38) must exist in ledger as STAGE-XX entries.
closed_stages="$(
  {
    grep -E '^\| \[x\] (2[8-9]|3[0-8]) \|' "$MASTER" || true
  } | sed -E 's/^\| \[x\] ([0-9]{2}) \|.*/\1/'
)"
for stage in $closed_stages; do
  id="STAGE-${stage}"
  if ! grep -q "stage_id: \"${id}\"" "$LEDGER"; then
    echo "missing evidence ledger entry for closed stage: ${id}"
    exit 1
  fi
done

# Every evidence file listed in ledger must exist.
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  if [[ ! -e "$file" ]]; then
    echo "missing evidence file referenced in ledger: $file"
    exit 1
  fi
done < <(
  {
    sed -n 's/^      - "\(.*\)"$/\1/p' "$LEDGER" || true
  } | {
    filter_repo_paths || true
  }
)

echo "evidence ledger gate: OK"
