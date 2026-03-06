#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source tests/platform/contract/platform_smoke_lib.sh

MODE="${MODE:-validate}"                  # validate | execute
K8S_PROVIDER="${K8S_PROVIDER:-auto}"      # auto | kind | k3d | external
K8S_PROFILE="${K8S_PROFILE:-kind-default}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/k8s-smoke}"
PROFILE_FILE="tests/platform/k8s/profiles/${K8S_PROFILE}.env"
CORE_IMAGE_TAG="${CORE_IMAGE_TAG:-art-core:k8s-smoke}"
AGENT_IMAGE_TAG="${AGENT_IMAGE_TAG:-art-agent:k8s-smoke}"
HOST_CORE_PORT="${HOST_CORE_PORT:-19070}"
HOST_AGENT_PORT="${HOST_AGENT_PORT:-19071}"

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

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found for execute mode"
  exit 2
fi

bash tests/platform/contract/check_docker_runtime_contract.sh
build_static_runtime_binaries >"$ARTIFACTS_DIR/build.log" 2>&1
docker build -f docker/core.Dockerfile -t "$CORE_IMAGE_TAG" . >"$ARTIFACTS_DIR/docker-build-core.log" 2>&1
docker build -f docker/agent.Dockerfile -t "$AGENT_IMAGE_TAG" . >"$ARTIFACTS_DIR/docker-build-agent.log" 2>&1

cleanup() {
  if [[ -n "${CORE_PF_PID:-}" ]]; then
    kill "${CORE_PF_PID}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${AGENT_PF_PID:-}" ]]; then
    kill "${AGENT_PF_PID}" >/dev/null 2>&1 || true
  fi
  if [[ "$SELECTED_PROVIDER" == "kind" ]]; then
    kind delete cluster --name "$K8S_CLUSTER_NAME" >/dev/null 2>&1 || true
  elif [[ "$SELECTED_PROVIDER" == "k3d" ]]; then
    k3d cluster delete "$K8S_CLUSTER_NAME" >/dev/null 2>&1 || true
  else
    kubectl delete namespace "$K8S_NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ "$SELECTED_PROVIDER" == "kind" ]]; then
  kind create cluster --name "$K8S_CLUSTER_NAME" --wait 60s >"$ARTIFACTS_DIR/cluster-create.log" 2>&1
  kind load docker-image --name "$K8S_CLUSTER_NAME" "$CORE_IMAGE_TAG" "$AGENT_IMAGE_TAG" >>"$ARTIFACTS_DIR/cluster-create.log" 2>&1
elif [[ "$SELECTED_PROVIDER" == "k3d" ]]; then
  k3d cluster create "$K8S_CLUSTER_NAME" --wait >"$ARTIFACTS_DIR/cluster-create.log" 2>&1
  k3d image import -c "$K8S_CLUSTER_NAME" "$CORE_IMAGE_TAG" "$AGENT_IMAGE_TAG" >>"$ARTIFACTS_DIR/cluster-create.log" 2>&1
fi

kubectl create namespace "$K8S_NAMESPACE" >"$ARTIFACTS_DIR/namespace.log" 2>&1
cat >"$ARTIFACTS_DIR/manifests.yaml" <<MANIFEST
apiVersion: apps/v1
kind: Deployment
metadata:
  name: art-core-smoke
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: art-core-smoke
  template:
    metadata:
      labels:
        app: art-core-smoke
    spec:
      containers:
        - name: core
          image: ${CORE_IMAGE_TAG}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: art-core-smoke
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: art-core-smoke
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: art-agent-smoke
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: art-agent-smoke
  template:
    metadata:
      labels:
        app: art-agent-smoke
    spec:
      containers:
        - name: agent
          image: ${AGENT_IMAGE_TAG}
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8081
---
apiVersion: v1
kind: Service
metadata:
  name: art-agent-smoke
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: art-agent-smoke
  ports:
    - port: 8081
      targetPort: 8081
MANIFEST

kubectl apply -f "$ARTIFACTS_DIR/manifests.yaml" >"$ARTIFACTS_DIR/apply.log" 2>&1
kubectl -n "$K8S_NAMESPACE" rollout status deployment/art-core-smoke --timeout=120s >"$ARTIFACTS_DIR/core-rollout.log" 2>&1
kubectl -n "$K8S_NAMESPACE" rollout status deployment/art-agent-smoke --timeout=120s >"$ARTIFACTS_DIR/agent-rollout.log" 2>&1

kubectl -n "$K8S_NAMESPACE" port-forward svc/art-core-smoke "${HOST_CORE_PORT}:8080" >"$ARTIFACTS_DIR/core-port-forward.log" 2>&1 &
CORE_PF_PID=$!
kubectl -n "$K8S_NAMESPACE" port-forward svc/art-agent-smoke "${HOST_AGENT_PORT}:8081" >"$ARTIFACTS_DIR/agent-port-forward.log" 2>&1 &
AGENT_PF_PID=$!

wait_for_http_ok "http://127.0.0.1:${HOST_CORE_PORT}/health" 60 1 "$ARTIFACTS_DIR/core-health-bootstrap.json"
wait_for_http_ok "http://127.0.0.1:${HOST_AGENT_PORT}/health" 60 1 "$ARTIFACTS_DIR/agent-health-bootstrap.json"

run_core_http_smoke "http://127.0.0.1:${HOST_CORE_PORT}" "$ARTIFACTS_DIR"
run_agent_http_smoke "http://127.0.0.1:${HOST_AGENT_PORT}" "$ARTIFACTS_DIR"

kubectl -n "$K8S_NAMESPACE" get pods -o wide >"$ARTIFACTS_DIR/pods.txt"
kubectl -n "$K8S_NAMESPACE" get svc >"$ARTIFACTS_DIR/services.txt"

cat > "$ARTIFACTS_DIR/evidence_container_test_kubernetes.txt" <<EVIDENCE
EVIDENCE_CONTAINER_TEST_kubernetes
provider=${SELECTED_PROVIDER}
status=PASS
namespace=${K8S_NAMESPACE}
cluster=${K8S_CLUSTER_NAME}
EVIDENCE

cat > "$ARTIFACTS_DIR/evidence_k8s_smoke.txt" <<EVIDENCE
EVIDENCE_K8S_SMOKE
status=PASS
provider=${SELECTED_PROVIDER}
profile=${K8S_PROFILE}
EVIDENCE

cleanup
trap - EXIT

echo "k8s smoke execute mode complete"
