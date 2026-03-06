#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

# shellcheck disable=SC1091
source tests/platform/contract/platform_smoke_lib.sh

MODE="${MODE:-validate}"                  # validate | execute
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/docker-smoke}"
CORE_IMAGE_TAG="${CORE_IMAGE_TAG:-art-core:smoke}"
AGENT_IMAGE_TAG="${AGENT_IMAGE_TAG:-art-agent:smoke}"
CORE_CONTAINER_NAME="${CORE_CONTAINER_NAME:-art-core-smoke}"
AGENT_CONTAINER_NAME="${AGENT_CONTAINER_NAME:-art-agent-smoke}"
HOST_CORE_PORT="${HOST_CORE_PORT:-18080}"
HOST_AGENT_PORT="${HOST_AGENT_PORT:-18081}"

mkdir -p "$ARTIFACTS_DIR"

print_plan() {
  cat <<PLAN
[docker smoke]
source_of_truth: formats/platform_support.yaml
mode: ${MODE}
core_image_tag: ${CORE_IMAGE_TAG}
agent_image_tag: ${AGENT_IMAGE_TAG}
steps:
1. verify docker runtime contract
2. build/pull core+agent images
3. run health -> ingest -> stream -> safe action(noop) smoke in container topology
4. collect evidence EVIDENCE_DOCKER_SMOKE and EVIDENCE_CONTAINER_TEST_docker
PLAN
}

print_plan | tee "$ARTIFACTS_DIR/plan.txt"

if [[ "$MODE" != "execute" ]]; then
  echo "validate mode complete"
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found for execute mode"
  exit 2
fi

bash tests/platform/contract/check_docker_runtime_contract.sh
build_static_runtime_binaries >"$ARTIFACTS_DIR/build.log" 2>&1

docker build -f docker/core.Dockerfile -t "$CORE_IMAGE_TAG" . >"$ARTIFACTS_DIR/docker-build-core.log" 2>&1
docker build -f docker/agent.Dockerfile -t "$AGENT_IMAGE_TAG" . >"$ARTIFACTS_DIR/docker-build-agent.log" 2>&1

docker rm -f "$CORE_CONTAINER_NAME" "$AGENT_CONTAINER_NAME" >/dev/null 2>&1 || true
cleanup() {
  docker logs "$CORE_CONTAINER_NAME" >"$ARTIFACTS_DIR/core-container.log" 2>&1 || true
  docker logs "$AGENT_CONTAINER_NAME" >"$ARTIFACTS_DIR/agent-container.log" 2>&1 || true
  docker rm -f "$CORE_CONTAINER_NAME" "$AGENT_CONTAINER_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name "$CORE_CONTAINER_NAME" -p "${HOST_CORE_PORT}:8080" "$CORE_IMAGE_TAG" >/dev/null
docker run -d --name "$AGENT_CONTAINER_NAME" -p "${HOST_AGENT_PORT}:8081" "$AGENT_IMAGE_TAG" >/dev/null

wait_for_http_ok "http://127.0.0.1:${HOST_CORE_PORT}/health" 60 1 "$ARTIFACTS_DIR/core-health-bootstrap.json"
wait_for_http_ok "http://127.0.0.1:${HOST_AGENT_PORT}/health" 60 1 "$ARTIFACTS_DIR/agent-health-bootstrap.json"

run_core_http_smoke "http://127.0.0.1:${HOST_CORE_PORT}" "$ARTIFACTS_DIR"
run_agent_http_smoke "http://127.0.0.1:${HOST_AGENT_PORT}" "$ARTIFACTS_DIR"

cat > "$ARTIFACTS_DIR/evidence_container_test_docker.txt" <<EVIDENCE
EVIDENCE_CONTAINER_TEST_docker
status=PASS
core_image=${CORE_IMAGE_TAG}
agent_image=${AGENT_IMAGE_TAG}
host_core_port=${HOST_CORE_PORT}
host_agent_port=${HOST_AGENT_PORT}
EVIDENCE

cat > "$ARTIFACTS_DIR/evidence_docker_smoke.txt" <<EVIDENCE
EVIDENCE_DOCKER_SMOKE
status=PASS
core_container=${CORE_CONTAINER_NAME}
agent_container=${AGENT_CONTAINER_NAME}
EVIDENCE

echo "docker smoke execute mode complete"
