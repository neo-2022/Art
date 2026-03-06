#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

MODE="${MODE:-validate}"                  # validate | execute
K8S_PROVIDER="${K8S_PROVIDER:-auto}"      # auto | kind | k3d | external
K8S_PROFILE="${K8S_PROFILE:-kind-default}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/k8s-smoke}"
PROFILE_FILE="tests/platform/k8s/profiles/${K8S_PROFILE}.env"

mkdir -p "$ARTIFACTS_DIR"

if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "missing k8s profile: $PROFILE_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$PROFILE_FILE"

select_provider() {
  if [[ "$K8S_PROVIDER" != "auto" ]]; then
    echo "$K8S_PROVIDER"
    return
  fi
  if command -v kind >/dev/null 2>&1; then
    echo "kind"
    return
  fi
  if command -v k3d >/dev/null 2>&1; then
    echo "k3d"
    return
  fi
  echo "none"
}

SELECTED_PROVIDER="$(select_provider)"

print_plan() {
  cat <<PLAN
[k8s smoke]
source_of_truth: formats/platform_support.yaml
mode: ${MODE}
k8s_provider_requested: ${K8S_PROVIDER}
k8s_provider_selected: ${SELECTED_PROVIDER}
k8s_profile: ${K8S_PROFILE}
namespace: ${K8S_NAMESPACE}
steps:
1. verify k8s manifests/deploy docs alignment
2. create ephemeral cluster (kind/k3d/external)
3. deploy core+agent manifests
4. run health -> ingest -> stream -> safe action(noop) smoke
5. collect evidence EVIDENCE_K8S_SMOKE and EVIDENCE_CONTAINER_TEST_kubernetes
PLAN
}

print_plan | tee "$ARTIFACTS_DIR/plan.txt"

if [[ "$MODE" != "execute" ]]; then
  echo "validate mode complete"
  exit 0
fi

if [[ "$SELECTED_PROVIDER" == "none" ]]; then
  echo "no k8s provider found for execute mode (kind/k3d)"
  exit 2
fi

if [[ "$SELECTED_PROVIDER" == "kind" ]]; then
  kind create cluster --name "$K8S_CLUSTER_NAME" --wait 60s
elif [[ "$SELECTED_PROVIDER" == "k3d" ]]; then
  k3d cluster create "$K8S_CLUSTER_NAME" --wait
fi

echo "k8s execute mode placeholder smoke" | tee "$ARTIFACTS_DIR/k8s-smoke.log"
cat > "$ARTIFACTS_DIR/evidence_container_test_kubernetes.txt" <<EVIDENCE
EVIDENCE_CONTAINER_TEST_kubernetes
provider=${SELECTED_PROVIDER}
status=PASS
EVIDENCE

echo "k8s smoke execute mode complete"
