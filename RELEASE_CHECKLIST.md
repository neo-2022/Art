# RELEASE CHECKLIST

## Source of truth
- `docs/release/release_process.md`
- `docs/release/versioning.md`
- `docs/ops/go_no_go_template.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Current release candidate
- Version: `v0.2.0-rc.2`
- Candidate commit: `1676a8a4c09be5067950aa45141e60c4aa315b2e`
- Changelog entry: `CHANGELOG.md#v0.2.0-rc.2---2026-03-06`
- Upgrade/downgrade suite: `release-regression` GitHub Actions job
- Image signing verify: `image-signing-verify` contract, implemented by `release-signing-verify` GitHub Actions job
- DR/backup requirements: `docs/ops/db_migration_runbook.md`, `docs/ops/deploy_systemd.md`, `docs/ops/deploy_k8s.md`
- GO/NO-GO decision sheet: `docs/governance/release_decisions/latest_go_no_go.md`
- Production scope statement: `Ubuntu native + Docker runtime + Kubernetes runtime are execute-gated for the current release scope; extended Linux matrix remains validate-only until ENABLE_NATURAL_MATRIX=true`
- Trust boundary proof: `docs/source/trust_boundary_hardening_v0_2.md`
- Browser surface baseline: `docs/source/browser_surface_hardening_v0_2.md`
- Ingress/perimeter baseline: `docs/source/ingress_perimeter_protection_v0_2.md`
- Pinned external adversarial harness: `docs/source/regart_adversarial_integration_harness_v0_2.md`

## Mandatory checks
- [x] `release-regression` green
- [x] `release-signing-verify` green
- [x] `stage24-docs-gate` green
- [x] `stage37-linux-hardening-gate` green
- [x] `docs/governance/release_decisions/latest_go_no_go.md` exists and is filled
- [ ] `trust boundary` proof attached for privileged or restricted rollout
- [ ] `browser surface` baseline attached for browser-facing rollout
- [ ] `ingress/perimeter` baseline attached for internet-exposed rollout
- [ ] pinned external adversarial harness proof attached for partner-exposed / `REGART` rollout
