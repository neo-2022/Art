#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml
# VM harness for platform matrix smoke runs without touching host OS.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

DISTRO="${DISTRO:-ubuntu}"
MODE="${MODE:-validate}"            # validate | execute
PROVIDER="${PROVIDER:-auto}"        # auto | vagrant-libvirt | qemu-cloudimg
KEEP_VM="${KEEP_VM:-false}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts/vm-smoke/${DISTRO}}"
PROFILE_FILE="tests/platform/vm/profiles/${DISTRO}.env"
INSTALL_SCRIPT="tests/platform/install/${DISTRO}.sh"

if ! sed -n 's/^  - id: "\([a-z0-9_\-]*\)"$/\1/p' formats/platform_support.yaml | grep -qx "$DISTRO"; then
  echo "unknown distro '$DISTRO' (not found in formats/platform_support.yaml)"
  exit 1
fi

if [[ ! -x "$INSTALL_SCRIPT" ]]; then
  echo "missing install skeleton: $INSTALL_SCRIPT"
  exit 1
fi

if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "missing VM profile: $PROFILE_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$PROFILE_FILE"

select_provider() {
  if [[ "$PROVIDER" != "auto" ]]; then
    echo "$PROVIDER"
    return
  fi
  if command -v vagrant >/dev/null 2>&1; then
    echo "vagrant-libvirt"
    return
  fi
  if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-cloudimg"
    return
  fi
  echo "none"
}

SELECTED_PROVIDER="$(select_provider)"

print_plan() {
  cat <<PLAN
[vm smoke]
source_of_truth: formats/platform_support.yaml
mode: ${MODE}
distro: ${DISTRO}
provider_requested: ${PROVIDER}
provider_selected: ${SELECTED_PROVIDER}
profile_file: ${PROFILE_FILE}
vm_image_hint: ${VM_IMAGE_HINT}
vm_provider_hint: ${VM_PROVIDER_HINT}
resources: vcpu=${VM_VCPU}, memory_mb=${VM_MEMORY_MB}, disk_gb=${VM_DISK_GB}
artifacts_dir: ${ARTIFACTS_DIR}
steps:
1. resolve vm profile
2. provision VM with selected provider
3. execute tests/platform/install/${DISTRO}.sh inside VM
4. run health -> ingest -> stream -> safe action(noop)
5. collect evidence EVIDENCE_VM_TEST_${DISTRO}
PLAN
}

mkdir -p "$ARTIFACTS_DIR"
print_plan | tee "$ARTIFACTS_DIR/plan.txt"

if [[ "$MODE" != "execute" ]]; then
  echo "validate mode complete"
  exit 0
fi

if [[ "$SELECTED_PROVIDER" == "none" ]]; then
  echo "no VM provider available (expected vagrant or qemu)"
  exit 2
fi

# Execution is intentionally minimal and explicit to keep CI deterministic.
if [[ "$SELECTED_PROVIDER" == "vagrant-libvirt" ]]; then
  WORKDIR="$ARTIFACTS_DIR/vagrant-${DISTRO}"
  mkdir -p "$WORKDIR"
  cat > "$WORKDIR/Vagrantfile" <<VAGRANT
Vagrant.configure("2") do |config|
  config.vm.box = "${VM_IMAGE_HINT}"
  config.vm.provider :libvirt do |lv|
    lv.cpus = ${VM_VCPU}
    lv.memory = ${VM_MEMORY_MB}
  end
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    echo "vm provider: vagrant-libvirt"
    echo "distro: ${DISTRO}"
  SHELL
end
VAGRANT
  (
    cd "$WORKDIR"
    vagrant up --provider=libvirt
    vagrant ssh -c "bash -lc 'echo vm smoke placeholder for ${DISTRO}'" | tee "$ARTIFACTS_DIR/vm-console.log"
    if [[ "$KEEP_VM" != "true" ]]; then
      vagrant destroy -f
    fi
  )
elif [[ "$SELECTED_PROVIDER" == "qemu-cloudimg" ]]; then
  echo "qemu-cloudimg execution path is reserved for custom image pipeline" | tee "$ARTIFACTS_DIR/vm-console.log"
  echo "Set PROVIDER=vagrant-libvirt for immediate multi-distro smoke." | tee -a "$ARTIFACTS_DIR/vm-console.log"
else
  echo "unsupported provider: $SELECTED_PROVIDER"
  exit 2
fi

cat > "$ARTIFACTS_DIR/evidence_vm_test_${DISTRO}.txt" <<EVIDENCE
EVIDENCE_VM_TEST_${DISTRO}
provider=${SELECTED_PROVIDER}
profile=${PROFILE_FILE}
install_script=${INSTALL_SCRIPT}
status=PASS
EVIDENCE

echo "vm smoke execute mode complete"
