# Go/No-Go Decision Template

## Source of truth
- `docs/ops/go_no_go_template.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `docs/release/release_process.md`
- `docs/ops/console_linux_prod_readiness.md`
- `docs/ops/platform-runtime-compatibility-matrix.md`

## Purpose
This template defines the single operational decision record before rollout. A release is allowed only after an explicit `GO` backed by required gates, evidence artifacts, and a verified rollback path.

## When to use
- production rollout;
- canary expansion;
- major upgrade or migration;
- rollout after security or performance remediation;
- release resume after an incident-driven freeze.

## Hard rules
1. `GO` is forbidden if at least one required check is red.
2. `GO` is forbidden if any release-blocker remains open in the risk register or checklist gates.
3. `GO` is forbidden if dual-write mismatch rate after the grace window is greater than `0`.
4. `GO` is forbidden if no rollback plan with a verified return point exists.
5. `GO` is forbidden if evidence artifacts are missing or not traceable to MASTER/checklists.

## Template

```md
# GO/NO-GO DECISION SHEET

## 1. General information
- Release ID:
- Commit / Tag:
- UTC date / time:
- Release window:
- Environment: `prod` | `staging`
- Strategy: `canary` | `phased` | `full`
- Initiator:
- Release Manager:
- Incident Commander:
- Communication channel:

## 2. Required gates (PASS / FAIL)
- [ ] All required GitHub checks = PASS
- [ ] All mandatory checklist gates = PASS
- [ ] Linux readiness suite = PASS
- [ ] Platform/runtime compatibility gate = PASS
- [ ] Security gates (`sast`, `sca`, `secrets`, `gitleaks`) = PASS
- [ ] Docs/source-of-truth gates = PASS
- [ ] Evidence ledger and delivery artifacts updated
- [ ] Rollback plan verified
- [ ] Alerting / observability gates enabled

## 3. Critical pre-release metrics
- Error budget:
- p95 latency:
- Ingest / Stream health:
- Snapshot consistency:
- Dual-write mismatch rate after grace window:
- Canary divergence incidents:
- Outbox / backlog status:
- Last smoke/e2e run:

## 4. Blockers and risks
- Open blockers:
- Accepted risks with owner:
- Immediate STOP rollout condition:
- Is a manual watch window required:

## 5. Rollout plan
- Step 1:
- PASS criteria for step 1:
- Step 2:
- PASS criteria for step 2:
- Step 3:
- PASS criteria for step 3:
- Observation timeout per step:

## 6. Rollback plan
- Rollback tag / commit:
- Rollback command / workflow:
- RTO:
- Post-rollback checks:
- Rollback owner:

## 7. Evidence
- CI run URL:
- Release artifacts:
- SBOM / checksums:
- Runtime logs:
- Screenshots / reports:
- Evidence IDs:

## 8. Decision
- Decision: `GO` | `NO-GO`
- Rationale:
- Additional conditions:
- Next control checkpoint:

## 9. Sign-off
- Release Manager:
- Tech Lead:
- SRE / Operations:
- Security:
- Product Owner (if required):
```

## Minimum completion order
1. Record the commit/tag and CI run first.
2. Mark only gates that actually passed.
3. Record metrics and blockers.
4. Only then set `GO` or `NO-GO`.
5. Attach the completed sheet to release evidence or the change record.

## What counts as PASS
- all required checks are green;
- every evidence link resolves to the current release candidate;
- rollback can be executed without ad-hoc operator improvisation;
- the decision is signed by the required roles.

## What counts as NO-GO
- at least one required gate is `pending` or `fail`;
- runtime state and documented state diverge;
- mandatory release artifacts are missing;
- Linux production readiness or platform compatibility is not confirmed.
