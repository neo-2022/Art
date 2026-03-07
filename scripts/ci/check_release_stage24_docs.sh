#!/usr/bin/env bash
set -euo pipefail
for f in docs/release/release_process.md docs/release/versioning.md docs/release/compat_matrix.md docs/release/downgrade.md docs/runbooks/release_signing_failed.md RELEASE_CHECKLIST.md CHANGELOG.md docs/ops/go_no_go_template.md docs/en/ops/go_no_go_template.md docs/governance/release_decisions/latest_go_no_go.md docs/source/ingress_perimeter_protection_v0_2.md docs/source/trust_boundary_hardening_v0_2.md docs/source/browser_surface_hardening_v0_2.md docs/source/regart_adversarial_integration_harness_v0_2.md docs/source/storage_pressure_protection_v0_2.md docs/source/startup_config_safety_validator_v0_2.md docs/source/queue_integrity_protection_v0_2.md docs/source/guard_self_observability_v0_2.md docs/runbooks/storage_pressure_high.md docs/runbooks/unsafe_startup_config_refused.md docs/runbooks/queue_integrity_violation.md docs/runbooks/guard_self_test_failed.md; do
  test -s "$f"
done
grep -q "manual" docs/release/release_process.md
grep -q "CI" docs/release/release_process.md
grep -q "SemVer" docs/release/release_process.md
grep -q "N-1" docs/release/downgrade.md
grep -q "инциденты читаются" docs/release/downgrade.md
grep -q "mitigations" docs/runbooks/release_signing_failed.md
grep -q "verification" docs/runbooks/release_signing_failed.md
grep -q "release_signing_failed" docs/governance/observability_gap_registry.md
grep -q "test-upgrade-downgrade\\|release-regression" RELEASE_CHECKLIST.md
grep -q "image-signing-verify" RELEASE_CHECKLIST.md
grep -q "GO/NO-GO\\|go_no_go" docs/release/release_process.md
grep -qi "trust boundary" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "browser surface" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "regart\\|partner-exposed" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "adversarial harness\\|harness proof" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "storage pressure" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "unsafe startup config" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "queue integrity" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
grep -qi "guard self-test\\|guard self test" docs/release/release_process.md RELEASE_CHECKLIST.md docs/governance/release_decisions/latest_go_no_go.md
bash scripts/ci/check_regart_adversarial_harness.sh
bash scripts/ci/check_go_no_go_gate.sh
echo "stage24 docs gate: OK"
