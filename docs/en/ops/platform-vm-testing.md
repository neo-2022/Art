# Platform VM Testing (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `tests/platform/vm/run_vm_smoke.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Why VM coverage matters
The VM track proves product readiness outside the developer host OS by running smoke flows in isolated Linux environments from the platform matrix. This closes the “works only on my machine” gap.

## What is already in place
- Unified VM harness: `tests/platform/vm/run_vm_smoke.sh`.
- VM profiles for each matrix distro: `tests/platform/vm/profiles/<distro>.env`.
- Unified evidence model:
  - `EVIDENCE_VM_MATRIX_READINESS`
  - `EVIDENCE_VM_TEST_<distro>`
- CI validation gate for VM skeletons: `scripts/ci/check_platform_vm_skeletons.sh`.

## Current CI mode
- Current mode: `ENABLE_NATURAL_MATRIX=false`.
- VM skeleton validity is checked in CI, while heavy natural VM execution remains disabled for every push.
- Once dedicated runners are attached, set `ENABLE_NATURAL_MATRIX=true` and enable VM smoke runs without changing product business logic.

## Local execution on Linux host
### 1) Validate mode (no VM boot)
```bash
DISTRO=ubuntu MODE=validate tests/platform/vm/run_vm_smoke.sh
```

### 2) Execute mode (with VM)
Requirements: `vagrant` + `libvirt` provider installed.

```bash
DISTRO=debian MODE=execute PROVIDER=vagrant-libvirt tests/platform/vm/run_vm_smoke.sh
```

Keep VM after execution:
```bash
DISTRO=fedora MODE=execute KEEP_VM=true tests/platform/vm/run_vm_smoke.sh
```

## Multi-version Linux support
Each distro profile is configured in `tests/platform/vm/profiles/<distro>.env`:
- `VM_IMAGE_HINT` — image/box reference for target Linux version;
- `VM_VCPU`, `VM_MEMORY_MB`, `VM_DISK_GB` — VM resources.

This enables running different Linux versions without modifying product code.

## Safety rule
- Platform differences are allowed only in install/packaging/test layers.
- `core/agent/browser` logic must not branch by distro.
- For enterprise distros (Astra/RED/etc.), BYOI (custom image) workflow is allowed.
