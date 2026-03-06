# Platform Support Matrix (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Why this exists
Platform support for Art and REGART must remain predictable for regulated and enterprise deployments. The engineering rule is strict: OS differences must not leak into `core/agent/browser` runtime logic. They are allowed only in packaging, installation, test scripts, and build profiles.

## Support levels
- `Level A (certified)`: Astra Linux SE, RED OS.
- `Level B (native)`: ALT, ROSA, OSnova, Ubuntu, Debian, AlmaLinux/Rocky, Fedora, openSUSE.
- `Level C (developer/universal)`: Arch, Calculate, MCC.

The canonical list and install methods are defined only in `formats/platform_support.yaml`.

## CI now
- Natural tests execute only on Ubuntu.
- Jobs for all other distributions are present and valid but disabled with `ENABLE_NATURAL_MATRIX=false`.
- This mode stays active until dedicated runners are attached.

## Release artifacts contract
- `artcore-<version>-linux-x86_64-static.tar.gz`
- `artagent-<version>-linux-x86_64-static.tar.gz`
- `SHA256SUMS`
- `sbom.spdx.json`
- Docker runtime skeletons: `docker/core.Dockerfile`, `docker/agent.Dockerfile` (`FROM scratch`, static binaries).

## Natural testing after project finalization
After setting `ENABLE_NATURAL_MATRIX=true`, the following install/smoke jobs are enabled:
- `debian-smoke`
- `fedora-smoke`
- `opensuse-smoke`
- `almalinux-rocky-smoke`
- `alt-smoke`
- `rosa-smoke`
- `astra-certified-smoke`
- `redos-certified-smoke`

## Evidence IDs
Mandatory evidence for the current stage:
- `EVIDENCE_PLATFORM_MATRIX`
- `EVIDENCE_CERTIFIED_BUILD`
- `EVIDENCE_DEB_PACKAGE_LAYOUT`
- `EVIDENCE_RPM_PACKAGE_LAYOUT`
- `EVIDENCE_SYSTEMD_UNITS`
- `EVIDENCE_DOCKER_REPRODUCIBLE`
- `EVIDENCE_SBOM`
- `EVIDENCE_REGART_INTEGRATION_UBUNTU_SMOKE`

Placeholders for future natural runs:
- `EVIDENCE_NATURAL_TEST_<distro>`
