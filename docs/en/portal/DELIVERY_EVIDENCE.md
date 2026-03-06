# Delivery Evidence Timeline

## Source of truth
- `docs/governance/evidence/evidence_ledger.yaml`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/governance/evidence/README.md`

## Why clients care
This page proves that the project advances through verifiable implementation steps: every closed stage is tied to concrete artifacts (logs/screenshots/CI gates), not paper-only statements.

## Key milestones
| Stage | Date | Delivered scope | Evidence |
|---|---|---|---|
| Stage 28 | 2026-03-06 | Console foundation + governance gates | `docs/governance/evidence/stage28_settings_profile_manager.png`, `check_stage28_docs.sh` |
| Stage 29 | 2026-03-06 | DNA Core v2 determinism and contracts | `docs/governance/evidence/stage29_step*.log`, `check_dna_assurance_program.sh` |
| Release governance | 2026-03-06 | Operational `GO/NO-GO` decision trail added to release process | `docs/governance/release_decisions/latest_go_no_go.md`, `check_go_no_go_gate.sh` |
| REGART integration checks | 2026-03-06 | Cross-repo compatibility checks | `tests/platform/contract/check_regart_cross_repo_parity.sh`, `tests/platform/contract/ubuntu_regart_smoke.sh` |

## How to verify
1. Open `docs/governance/evidence/evidence_ledger.yaml`.
2. Run `reproducible_checks` commands for selected entry.
3. Confirm files from `evidence_files` exist.

## Transparency policy
- A closed stage without an evidence record is a process-law violation.
- CI gate `check_evidence_ledger.sh` blocks such inconsistency.
