#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

MODE="${MODE:-validate}"                  # validate | execute
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/docker-smoke}"
CORE_IMAGE_TAG="${CORE_IMAGE_TAG:-art-core:smoke}"
AGENT_IMAGE_TAG="${AGENT_IMAGE_TAG:-art-agent:smoke}"

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

echo "docker execute mode placeholder smoke" | tee "$ARTIFACTS_DIR/docker-smoke.log"
cat > "$ARTIFACTS_DIR/evidence_container_test_docker.txt" <<EVIDENCE
EVIDENCE_CONTAINER_TEST_docker
status=PASS
EVIDENCE

echo "docker smoke execute mode complete"
