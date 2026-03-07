#!/usr/bin/env bash
set -euo pipefail

bash scripts/tests/panel0_linux_prod_readiness.sh
bash scripts/tests/console_linux_prod_readiness.sh
bash scripts/ci/check_platform_support_consistency.sh
bash scripts/ci/check_platform_install_skeletons.sh
bash scripts/ci/check_platform_vm_skeletons.sh
bash scripts/ci/check_platform_container_k8s_skeletons.sh
bash scripts/ci/check_platform_runtime_compatibility.sh
bash scripts/ci/check_certified_profile.sh
bash scripts/ci/check_go_no_go_gate.sh
bash tests/platform/contract/check_package_layout_contract.sh
bash tests/platform/contract/check_docker_runtime_contract.sh
bash tests/platform/contract/check_regart_cross_repo_parity.sh

grep -q "dna_core_v2_enabled" docs/ops/console_linux_prod_readiness.md
grep -q "dna divergence gate" docs/ops/console_linux_prod_readiness.md
grep -q "privacy alert gate" docs/ops/console_linux_prod_readiness.md
grep -q "Source of truth" docs/ops/platform-support.md
grep -q "Source of truth" docs/en/ops/platform-support.md
grep -q "Source of truth" docs/ops/platform-vm-testing.md
grep -q "Source of truth" docs/en/ops/platform-vm-testing.md
grep -q "Source of truth" docs/ops/platform-container-k8s-testing.md
grep -q "Source of truth" docs/en/ops/platform-container-k8s-testing.md
grep -q "Source of truth" docs/ops/platform-runtime-compatibility-matrix.md
grep -q "Source of truth" docs/en/ops/platform-runtime-compatibility-matrix.md
grep -q "Source of truth" docs/security/fstec-certified-profile.md
grep -q "Source of truth" docs/en/security/fstec-certified-profile.md
grep -q "^| observability_gap.dna_canary_divergence |" docs/governance/observability_gap_registry.md
grep -q "^| observability_gap.evidence_privacy_violation |" docs/governance/observability_gap_registry.md
grep -q "^| observability_gap.trust_boundary_violation |" docs/governance/observability_gap_registry.md
grep -q "^| observability_gap.browser_surface_policy_degraded |" docs/governance/observability_gap_registry.md
test -s docs/source/trust_boundary_hardening_v0_2.md
test -s docs/source/browser_surface_hardening_v0_2.md
test -s docs/runbooks/trust_boundary_violation.md
test -s docs/runbooks/browser_surface_policy_degraded.md
test -s docs/source/storage_pressure_protection_v0_2.md
test -s docs/source/startup_config_safety_validator_v0_2.md
test -s docs/source/queue_integrity_protection_v0_2.md
test -s docs/source/guard_self_observability_v0_2.md
test -s docs/runbooks/storage_pressure_high.md
test -s docs/runbooks/unsafe_startup_config_refused.md
test -s docs/runbooks/queue_integrity_violation.md
test -s docs/runbooks/guard_self_test_failed.md
grep -q "trusted actor context" docs/source/trust_boundary_hardening_v0_2.md
grep -q "CSP" docs/source/browser_surface_hardening_v0_2.md
grep -qi "high watermark" docs/source/storage_pressure_protection_v0_2.md
grep -qi "unsafe startup config" docs/source/startup_config_safety_validator_v0_2.md
grep -qi "duplicate flood" docs/source/queue_integrity_protection_v0_2.md
grep -qi "self-test" docs/source/guard_self_observability_v0_2.md
test -s artifacts/regart-parity/report.json
grep -q "platform-vm-skeleton-gate" .github/workflows/platform_matrix_stage37.yml
grep -q "platform-runtime-compatibility-gate" .github/workflows/platform_matrix_stage37.yml

echo "stage37 linux hardening gate: OK"
