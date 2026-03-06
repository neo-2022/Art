# Certified Build Profile (FSTEC-Oriented)

## Source of truth
- `formats/platform_support.yaml`
- `Cargo.toml` (`profile.general`, `profile.certified`)
- `scripts/ci/check_certified_profile.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Purpose
The `certified` profile defines a strict build contour for Level A platforms (Astra Linux SE, RED OS). Even while natural tests are Ubuntu-only, certified contract checks must already pass in CI.

## Mandatory certified invariants
- No dynamic extension loading (`dlopen`, `libloading`) in the codebase.
- Dependency allowlist is fixed and CI-enforced.
- Build reproducibility controls are active: lockfiles + fixed profile flags.
- Release pipeline contains an artifact signing hook.

## CI now
- `scripts/ci/check_certified_profile.sh` runs on Ubuntu.
- `--profile certified` build is verified for both `art-core` and `art-agent`.
- VM track (`tests/platform/vm/run_vm_smoke.sh`) is used as an additional non-host validation layer, without relaxing certified invariants.

## Natural testing after final stage
After `ENABLE_NATURAL_MATRIX=true`, `certified` checks are also validated in:
- `astra-certified-smoke`
- `redos-certified-smoke`

## Scope note
This page defines profile behavior and checks only. Broader compliance and operations requirements remain in checklist/runbook documentation.
