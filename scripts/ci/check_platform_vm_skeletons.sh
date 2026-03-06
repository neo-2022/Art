#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

YAML_FILE="formats/platform_support.yaml"
VM_RUNNER="tests/platform/vm/run_vm_smoke.sh"
RU_DOC="docs/ops/platform-vm-testing.md"
EN_DOC="docs/en/ops/platform-vm-testing.md"

test -s "$YAML_FILE"
test -x "$VM_RUNNER"
grep -q "Source of truth: formats/platform_support.yaml" "$VM_RUNNER"
grep -q 'MODE="${MODE:-validate}"' "$VM_RUNNER"
grep -q 'EVIDENCE_VM_TEST_' "$VM_RUNNER"

test -s "$RU_DOC"
test -s "$EN_DOC"
grep -q "^## Source of truth" "$RU_DOC"
grep -q "^## Source of truth" "$EN_DOC"
grep -q "ENABLE_NATURAL_MATRIX=false" "$RU_DOC"
grep -q "ENABLE_NATURAL_MATRIX=false" "$EN_DOC"

grep -q "^vm_test_definition:" "$YAML_FILE"
grep -q "EVIDENCE_VM_MATRIX_READINESS" "$YAML_FILE"

missing=0
while IFS= read -r distro; do
  [[ -z "$distro" ]] && continue
  profile="tests/platform/vm/profiles/${distro}.env"
  if [[ ! -s "$profile" ]]; then
    echo "missing VM profile: $profile"
    missing=1
    continue
  fi
  grep -q '^VM_DISTRO="' "$profile" || { echo "bad profile: $profile (VM_DISTRO)"; missing=1; }
  grep -q '^VM_PROVIDER_HINT="' "$profile" || { echo "bad profile: $profile (VM_PROVIDER_HINT)"; missing=1; }
  grep -q '^VM_IMAGE_HINT="' "$profile" || { echo "bad profile: $profile (VM_IMAGE_HINT)"; missing=1; }
  grep -q '^VM_VCPU="' "$profile" || { echo "bad profile: $profile (VM_VCPU)"; missing=1; }
  grep -q '^VM_MEMORY_MB="' "$profile" || { echo "bad profile: $profile (VM_MEMORY_MB)"; missing=1; }
  grep -q '^VM_DISK_GB="' "$profile" || { echo "bad profile: $profile (VM_DISK_GB)"; missing=1; }
done < <(sed -n 's/^  - id: "\([a-z0-9_\-]*\)"$/\1/p' "$YAML_FILE")

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "platform VM skeleton gate: OK"
