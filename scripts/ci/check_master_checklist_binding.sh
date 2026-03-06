#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MASTER="docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md"

test -s "$MASTER"

missing_ref=0
for file in docs/source/checklists/CHECKLIST_[0-9][0-9]_*.md; do
  [[ "$file" == *"CHECKLIST_00_MASTER_ART_REGART.md"* ]] && continue
  if [[ "$file" == "docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md" ]]; then
    continue
  fi
  if ! grep -q "CHECKLIST_00_MASTER_ART_REGART.md" "$file"; then
    echo "missing master reference in checklist: $file"
    missing_ref=1
  fi
  base_name="$(basename "$file")"
  if ! grep -q "$base_name" "$MASTER"; then
    echo "master table missing checklist file reference: $base_name"
    missing_ref=1
  fi
done

if [[ "$missing_ref" -ne 0 ]]; then
  exit 1
fi

echo "master checklist binding gate: OK"
