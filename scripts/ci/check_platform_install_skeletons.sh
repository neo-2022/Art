#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

YAML_FILE="formats/platform_support.yaml"

test -s "$YAML_FILE"

while IFS= read -r distro; do
  [[ -z "$distro" ]] && continue
  script="tests/platform/install/${distro}.sh"
  test -x "$script"
  grep -q "Source of truth: formats/platform_support.yaml" "$script"
  grep -q "MODE=\"\${MODE:-validate}\"" "$script"
  grep -q 'EVIDENCE_NATURAL_TEST_${DISTRO}' "$script"
done < <(sed -n 's/^  - id: "\([a-z0-9_\-]*\)"$/\1/p' "$YAML_FILE")

echo "platform install skeletons gate: OK"
