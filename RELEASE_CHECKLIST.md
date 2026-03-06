# RELEASE CHECKLIST

## Source of truth
- `docs/release/release_process.md`
- `docs/release/versioning.md`
- `docs/ops/go_no_go_template.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Current release candidate
- Version: `v0.2.0-rc.1`
- Changelog entry: `CHANGELOG.md#v0.2.0-rc.1---2026-03-06`
- Upgrade/downgrade suite: `release-regression` GitHub Actions job
- Image signing verify: `image-signing-verify` contract, implemented by `release-signing-verify` GitHub Actions job
- DR/backup requirements: `docs/ops/db_migration_runbook.md`, `docs/ops/deploy_systemd.md`, `docs/ops/deploy_k8s.md`
- GO/NO-GO decision sheet: `docs/governance/release_decisions/latest_go_no_go.md`

## Mandatory checks
- [x] `release-regression` green
- [x] `release-signing-verify` green
- [x] `stage24-docs-gate` green
- [x] `stage37-linux-hardening-gate` green
- [x] `docs/governance/release_decisions/latest_go_no_go.md` exists and is filled
