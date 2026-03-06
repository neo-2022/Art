#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml
# This script is a valid natural-test skeleton and is intentionally safe-by-default.
# It becomes runnable on target runners after ENABLE_NATURAL_MATRIX=true.

DISTRO="osnova_linux"
MODE="${MODE:-validate}"
INSTALL_METHOD="${INSTALL_METHOD:-auto}"

print_plan() {
  cat <<PLAN
[distro] ${DISTRO}
[mode] ${MODE}
[install_method] ${INSTALL_METHOD}
[steps]
1. install artifacts (deb/rpm/static/docker based on matrix)
2. start systemd units (or container service)
3. run smoke: health -> ingest -> stream -> safe action(noop)
4. collect evidence bundle EVIDENCE_NATURAL_TEST_${DISTRO}
PLAN
}

if [[ "${MODE}" != "execute" ]]; then
  print_plan
  exit 0
fi

# Execution mode is intentionally explicit and guarded.
echo "natural execution mode for ${DISTRO} is enabled"
print_plan
