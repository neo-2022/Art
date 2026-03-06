#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

YAML_FILE="formats/platform_support.yaml"
RU_OPS="docs/ops/platform-support.md"
EN_OPS="docs/en/ops/platform-support.md"
RU_VM="docs/ops/platform-vm-testing.md"
EN_VM="docs/en/ops/platform-vm-testing.md"
RU_CONTAINER_K8S="docs/ops/platform-container-k8s-testing.md"
EN_CONTAINER_K8S="docs/en/ops/platform-container-k8s-testing.md"
RU_RUNTIME_MATRIX="docs/ops/platform-runtime-compatibility-matrix.md"
EN_RUNTIME_MATRIX="docs/en/ops/platform-runtime-compatibility-matrix.md"
RU_SEC="docs/security/fstec-certified-profile.md"
EN_SEC="docs/en/security/fstec-certified-profile.md"

for f in "$YAML_FILE" "$RU_OPS" "$EN_OPS" "$RU_VM" "$EN_VM" "$RU_CONTAINER_K8S" "$EN_CONTAINER_K8S" "$RU_RUNTIME_MATRIX" "$EN_RUNTIME_MATRIX" "$RU_SEC" "$EN_SEC"; do
  test -s "$f"
done
test -s "docker/core.Dockerfile"
test -s "docker/agent.Dockerfile"
grep -q '^FROM scratch$' docker/core.Dockerfile
grep -q '^FROM scratch$' docker/agent.Dockerfile
grep -q "artcore-<version>-linux-x86_64-static.tar.gz" "$RU_OPS"
grep -q "artagent-<version>-linux-x86_64-static.tar.gz" "$RU_OPS"
grep -q "artcore-<version>-linux-x86_64-static.tar.gz" "$EN_OPS"
grep -q "artagent-<version>-linux-x86_64-static.tar.gz" "$EN_OPS"

grep -q "^## Source of truth" "$RU_OPS"
grep -q "^## Source of truth" "$EN_OPS"
grep -q "^## Source of truth" "$RU_VM"
grep -q "^## Source of truth" "$EN_VM"
grep -q "^## Source of truth" "$RU_CONTAINER_K8S"
grep -q "^## Source of truth" "$EN_CONTAINER_K8S"
grep -q "^## Source of truth" "$RU_RUNTIME_MATRIX"
grep -q "^## Source of truth" "$EN_RUNTIME_MATRIX"
grep -q "^## Source of truth" "$RU_SEC"
grep -q "^## Source of truth" "$EN_SEC"

grep -q "ENABLE_NATURAL_MATRIX=false" "$RU_OPS"
grep -q "ENABLE_NATURAL_MATRIX=false" "$EN_OPS"
grep -q "ENABLE_NATURAL_MATRIX=false" "$RU_VM"
grep -q "ENABLE_NATURAL_MATRIX=false" "$EN_VM"
grep -q "ENABLE_NATURAL_MATRIX=false" "$RU_CONTAINER_K8S"
grep -q "ENABLE_NATURAL_MATRIX=false" "$EN_CONTAINER_K8S"
grep -q "ENABLE_NATURAL_MATRIX=false" "$RU_RUNTIME_MATRIX"
grep -q "ENABLE_NATURAL_MATRIX=false" "$EN_RUNTIME_MATRIX"

grep -q "^platforms:" "$YAML_FILE"
grep -q "id: \"ubuntu\"" "$YAML_FILE"
grep -q "id: \"astra_linux_se\"" "$YAML_FILE"
grep -q "id: \"redos\"" "$YAML_FILE"
grep -q "^vm_test_definition:" "$YAML_FILE"
grep -q "EVIDENCE_VM_MATRIX_READINESS" "$YAML_FILE"
grep -q "^container_test_surfaces:" "$YAML_FILE"
grep -q "EVIDENCE_DOCKER_SMOKE" "$YAML_FILE"
grep -q "EVIDENCE_K8S_SMOKE" "$YAML_FILE"
grep -q "^runtime_compatibility_matrix:" "$YAML_FILE"

# Ensure install skeleton script exists for every platform id in source-of-truth.
missing=0
while IFS= read -r distro; do
  [[ -z "$distro" ]] && continue
  script="tests/platform/install/${distro}.sh"
  if [[ ! -x "$script" ]]; then
    echo "missing executable install skeleton: $script"
    missing=1
  fi
done < <(sed -n 's/^  - id: "\([a-z0-9_\-]*\)"$/\1/p' "$YAML_FILE")

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

# If platform matrix changed in this commit range, require both RU and EN docs to be touched.
base_ref="${GITHUB_BASE_REF:-main}"
if git rev-parse --verify "origin/${base_ref}" >/dev/null 2>&1; then
  base_commit="$(git merge-base HEAD "origin/${base_ref}")"
else
  base_commit="$(git rev-list --max-parents=0 HEAD | tail -n 1)"
fi
changed_files="$(git diff --name-only "${base_commit}...HEAD" 2>/dev/null || true)"
working_tree_files="$(git status --porcelain | awk '{print $2}' || true)"
changed_files="$(printf '%s\n%s\n' "$changed_files" "$working_tree_files" | sed '/^$/d' | sort -u)"
if grep -qx "$YAML_FILE" <<<"$changed_files"; then
  for required in "$RU_OPS" "$EN_OPS" "$RU_SEC" "$EN_SEC"; do
    if ! grep -qx "$required" <<<"$changed_files"; then
      echo "platform matrix changed but synced doc missing in same commit range: $required"
      exit 1
    fi
  done
  for required in "$RU_VM" "$EN_VM"; do
    if ! grep -qx "$required" <<<"$changed_files"; then
      echo "platform matrix changed but synced VM doc missing in same commit range: $required"
      exit 1
    fi
  done
  for required in "$RU_CONTAINER_K8S" "$EN_CONTAINER_K8S"; do
    if ! grep -qx "$required" <<<"$changed_files"; then
      echo "platform matrix changed but synced container/k8s doc missing in same commit range: $required"
      exit 1
    fi
  done
  for required in "$RU_RUNTIME_MATRIX" "$EN_RUNTIME_MATRIX"; do
    if ! grep -qx "$required" <<<"$changed_files"; then
      echo "platform matrix changed but synced runtime matrix doc missing in same commit range: $required"
      exit 1
    fi
  done
fi

echo "platform support consistency gate: OK"
