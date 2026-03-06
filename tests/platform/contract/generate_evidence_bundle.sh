#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-artifacts/platform-evidence}"
mkdir -p "$OUT_DIR"

cat > "$OUT_DIR/evidence_ids.txt" <<'IDS'
EVIDENCE_PLATFORM_MATRIX
EVIDENCE_CERTIFIED_BUILD
EVIDENCE_DEB_PACKAGE_LAYOUT
EVIDENCE_RPM_PACKAGE_LAYOUT
EVIDENCE_SYSTEMD_UNITS
EVIDENCE_DOCKER_REPRODUCIBLE
EVIDENCE_SBOM
EVIDENCE_REGART_INTEGRATION_UBUNTU_SMOKE
EVIDENCE_NATURAL_TEST_astra_linux_se
EVIDENCE_NATURAL_TEST_redos
EVIDENCE_NATURAL_TEST_alt_linux
EVIDENCE_NATURAL_TEST_rosa_linux
EVIDENCE_NATURAL_TEST_osnova_linux
EVIDENCE_NATURAL_TEST_ubuntu
EVIDENCE_NATURAL_TEST_debian
EVIDENCE_NATURAL_TEST_almalinux
EVIDENCE_NATURAL_TEST_rocky_linux
EVIDENCE_NATURAL_TEST_fedora
EVIDENCE_NATURAL_TEST_opensuse_leap
EVIDENCE_NATURAL_TEST_arch_linux
EVIDENCE_NATURAL_TEST_calculate_linux
EVIDENCE_NATURAL_TEST_mcc_linux
IDS

cat > "$OUT_DIR/EVIDENCE_PLATFORM_MATRIX.txt" <<'EOF2'
status=generated
source_of_truth=formats/platform_support.yaml
EOF2

cat > "$OUT_DIR/EVIDENCE_CERTIFIED_BUILD.txt" <<'EOF2'
status=generated
check=scripts/ci/check_certified_profile.sh
EOF2

cat > "$OUT_DIR/EVIDENCE_DEB_PACKAGE_LAYOUT.txt" <<'EOF2'
status=generated
check=tests/platform/contract/check_package_layout_contract.sh
layout=packaging/deb
EOF2

cat > "$OUT_DIR/EVIDENCE_RPM_PACKAGE_LAYOUT.txt" <<'EOF2'
status=generated
check=tests/platform/contract/check_package_layout_contract.sh
layout=packaging/rpm
EOF2

cat > "$OUT_DIR/EVIDENCE_SYSTEMD_UNITS.txt" <<'EOF2'
status=generated
unit=systemd/art-vacuum.service
EOF2

cat > "$OUT_DIR/EVIDENCE_DOCKER_REPRODUCIBLE.txt" <<'EOF2'
status=policy-defined
note=docker reproducibility contract fixed in docs/platform-support and platform tests; natural distro execution deferred by ENABLE_NATURAL_MATRIX flag.
EOF2

cat > "$OUT_DIR/EVIDENCE_SBOM.txt" <<'EOF2'
status=generated-in-release-pipeline
workflow=.github/workflows/release_stage04.yml
EOF2

cat > "$OUT_DIR/EVIDENCE_REGART_INTEGRATION_UBUNTU_SMOKE.txt" <<'EOF2'
status=generated
check=tests/platform/contract/ubuntu_regart_smoke.sh
EOF2

for d in astra_linux_se redos alt_linux rosa_linux osnova_linux ubuntu debian almalinux rocky_linux fedora opensuse_leap arch_linux calculate_linux mcc_linux; do
  cat > "$OUT_DIR/EVIDENCE_NATURAL_TEST_${d}.txt" <<EOF2
status=placeholder
activation=ENABLE_NATURAL_MATRIX=true
install_script=tests/platform/install/${d}.sh
EOF2
done

echo "evidence bundle generated: $OUT_DIR"
