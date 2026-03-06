#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

YAML_FILE="formats/platform_support.yaml"
DOCKER_RUNNER="tests/platform/container/run_docker_smoke.sh"
K8S_RUNNER="tests/platform/k8s/run_k8s_smoke.sh"
K8S_KIND_PROFILE="tests/platform/k8s/profiles/kind-default.env"
K8S_K3D_PROFILE="tests/platform/k8s/profiles/k3d-default.env"
RU_DOC="docs/ops/platform-container-k8s-testing.md"
EN_DOC="docs/en/ops/platform-container-k8s-testing.md"

test -s "$YAML_FILE"

grep -q '^container_test_surfaces:' "$YAML_FILE"
grep -q 'docker_runtime' "$YAML_FILE"
grep -q 'kubernetes_runtime' "$YAML_FILE"
grep -q 'EVIDENCE_DOCKER_SMOKE' "$YAML_FILE"
grep -q 'EVIDENCE_K8S_SMOKE' "$YAML_FILE"

test -x "$DOCKER_RUNNER"
grep -q 'Source of truth: formats/platform_support.yaml' "$DOCKER_RUNNER"
grep -q 'MODE="${MODE:-validate}"' "$DOCKER_RUNNER"
grep -q 'EVIDENCE_CONTAINER_TEST_docker' "$DOCKER_RUNNER"

test -x "$K8S_RUNNER"
grep -q 'Source of truth: formats/platform_support.yaml' "$K8S_RUNNER"
grep -q 'MODE="${MODE:-validate}"' "$K8S_RUNNER"
grep -q 'EVIDENCE_CONTAINER_TEST_kubernetes' "$K8S_RUNNER"

for profile in "$K8S_KIND_PROFILE" "$K8S_K3D_PROFILE"; do
  test -s "$profile"
  grep -q '^K8S_CLUSTER_NAME="' "$profile"
  grep -q '^K8S_NAMESPACE="' "$profile"
  grep -q '^K8S_EXPECTED_VERSION="' "$profile"
done

for doc in "$RU_DOC" "$EN_DOC"; do
  test -s "$doc"
  grep -q '^## Source of truth' "$doc"
  grep -q 'ENABLE_NATURAL_MATRIX=false' "$doc"
done

echo "platform container+k8s skeleton gate: OK"
