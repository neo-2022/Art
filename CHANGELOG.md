# Changelog

## v0.2.0-rc.2 - 2026-03-06

- Merged runtime execute hardening for production surfaces into `main`.
- Replaced Docker and Kubernetes stage37 placeholder smoke paths with real execute-smoke validation on Ubuntu runners.
- Added runtime bind-host controls for `art-core` and `art-agent` to support container and cluster networking without distro-specific code forks.
- Updated platform source-of-truth, runtime compatibility docs, and evidence ledger to reflect execute-gated production surfaces: Ubuntu native, Docker runtime, Kubernetes runtime.

## v0.2.0-rc.1 - 2026-03-06

- Consolidated stage 28..38 governance, contracts, evidence ledger, and Linux hardening into `main`.
- Added operational `GO/NO-GO` release decision templates in RU/EN and bound them to release/stage37 process gates.
- Added release decision registry under `docs/governance/release_decisions/`.
- Restored missing root-level release hygiene artifacts: `CHANGELOG.md` and `RELEASE_CHECKLIST.md`.
