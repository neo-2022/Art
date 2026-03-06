#!/usr/bin/env bash
set -euo pipefail

bash scripts/ci/check_platform_support_consistency.sh
bash scripts/ci/check_certified_profile.sh
bash tests/platform/contract/check_package_layout_contract.sh
bash tests/platform/contract/check_docker_runtime_contract.sh
bash tests/platform/contract/ubuntu_regart_smoke.sh
bash tests/platform/contract/generate_evidence_bundle.sh "artifacts/platform-evidence"

echo "platform contract suite: OK"
