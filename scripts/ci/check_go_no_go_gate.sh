#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

has_open_checkboxes() {
  local file="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -q '^- \[ \]' "$file"
  else
    grep -Eq '^- \[ \]' "$file"
  fi
}

RU_TEMPLATE="docs/ops/go_no_go_template.md"
EN_TEMPLATE="docs/en/ops/go_no_go_template.md"
DECISIONS_DIR="docs/governance/release_decisions"
README_FILE="${DECISIONS_DIR}/README.md"
LATEST_FILE="${DECISIONS_DIR}/latest_go_no_go.md"

for f in "$RU_TEMPLATE" "$EN_TEMPLATE" "$README_FILE" "$LATEST_FILE"; do
  test -s "$f"
done

grep -q "^## Source of truth" "$RU_TEMPLATE"
grep -q "^## Source of truth" "$EN_TEMPLATE"
grep -q "^## Source of truth" "$README_FILE"
grep -q "^## Source of truth" "$LATEST_FILE"

grep -Eq '^- Release ID: .+' "$LATEST_FILE"
grep -Eq '^- Commit / Tag: .+' "$LATEST_FILE"
grep -Eq '^- UTC date / time: .+' "$LATEST_FILE"
grep -Eq '^- Environment: .+' "$LATEST_FILE"
grep -Eq '^- CI run URL: .+' "$LATEST_FILE"
grep -Eq '^- Decision: `GO`$|^- Decision: `NO-GO`$' "$LATEST_FILE"

if grep -Eq '^- Decision: `GO`$' "$LATEST_FILE"; then
  if has_open_checkboxes "$LATEST_FILE"; then
    echo "GO/NO-GO gate: GO decision contains unchecked mandatory items"
    exit 1
  fi
fi

grep -q "go_no_go_template.md" docs/release/release_process.md
grep -q "go_no_go_template.md" docs/README.md
grep -q "go_no_go_template.md" docs/en/README.md

echo "go/no-go gate: OK"
