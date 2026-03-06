#!/usr/bin/env bash
set -euo pipefail

bash scripts/tests/panel0_linux_prod_readiness.sh
bash scripts/tests/console_linux_prod_readiness.sh
bash scripts/ci/check_platform_support_consistency.sh
bash scripts/ci/check_platform_install_skeletons.sh
bash scripts/ci/check_certified_profile.sh
bash tests/platform/contract/check_package_layout_contract.sh
bash tests/platform/contract/check_docker_runtime_contract.sh

grep -q "dna_core_v2_enabled" docs/ops/console_linux_prod_readiness.md
grep -q "dna divergence gate" docs/ops/console_linux_prod_readiness.md
grep -q "privacy alert gate" docs/ops/console_linux_prod_readiness.md
grep -q "Source of truth" docs/ops/platform-support.md
grep -q "Source of truth" docs/en/ops/platform-support.md
grep -q "Source of truth" docs/security/fstec-certified-profile.md
grep -q "Source of truth" docs/en/security/fstec-certified-profile.md
grep -q "^| observability_gap.dna_canary_divergence |" docs/governance/observability_gap_registry.md
grep -q "^| observability_gap.evidence_privacy_violation |" docs/governance/observability_gap_registry.md

echo "stage37 linux hardening gate: OK"
