# GO/NO-GO DECISION SHEET

## Source of truth
- `docs/ops/go_no_go_template.md`
- `docs/release/release_process.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## 1. General information
- Release ID: `v0.2.0-rc.2-production-candidate`
- Commit / Tag: `1676a8a4c09be5067950aa45141e60c4aa315b2e`
- UTC date / time: `2026-03-06T17:05:38Z`
- Release window: `production candidate validation`
- Environment: `production-candidate`
- Strategy: `canary on Ubuntu-native plus execute-gated container surfaces`
- Initiator: `neo-2022`
- Release Manager: `neo-2022`
- Incident Commander: `neo-2022`
- Communication channel: `GitHub PR #18 / Actions`

## 2. Required gates (PASS / FAIL)
- [x] All required GitHub checks = PASS
- [x] All mandatory checklist gates = PASS
- [x] Linux readiness suite = PASS
- [x] Platform/runtime compatibility gate = PASS
- [x] Security gates (`sast`, `sca`, `secrets`, `gitleaks`) = PASS
- [x] Docs/source-of-truth gates = PASS
- [x] Evidence ledger and delivery artifacts updated
- [x] Rollback plan verified
- [x] Alerting / observability gates enabled

## 3. Critical pre-release metrics
- Error budget: `within allowed budget for production candidate validation`
- p95 latency: `within stage34 and stage35 budgets`
- Ingest / Stream health: `PASS`
- Snapshot consistency: `PASS`
- Dual-write mismatch rate after grace window: `0`
- Canary divergence incidents: `0 active`
- Outbox / backlog status: `OK`
- Last smoke/e2e run: `GitHub Actions PR #20 checks + local execute smoke evidence refresh on merged main baseline`

## 4. Blockers and risks
- Open blockers: `none`
- Accepted risks with owner: `natural VM and non-Ubuntu native matrix remain validate-only until dedicated runners are enabled with ENABLE_NATURAL_MATRIX=true; owner neo-2022`
- Immediate STOP rollout condition: `any required gate fail, any active divergence incident, any Docker/Kubernetes execute smoke regression, any release-blocker in risk register`
- Is a manual watch window required: `yes, for production rollout`

## 5. Rollout plan
- Step 1: `freeze merged main baseline and refresh release metadata for rc.2`
- PASS criteria for step 1: `release checklist, changelog, and production-candidate GO/NO-GO reference the merged main commit`
- Step 2: `validate mandatory execute-gated surfaces: Ubuntu native, Docker runtime, Kubernetes runtime`
- PASS criteria for step 2: `stage37 and platform runtime compatibility gates remain green with execute smoke evidence`
- Step 3: `create signed release tag and publish release artifacts through CI`
- PASS criteria for step 3: `stage24/stage37 gates, release signing verification, and artifact publication remain green`
- Observation timeout per step: `15 minutes`

## 6. Rollback plan
- Rollback tag / commit: `f6aa77bd109cc624c7a6c2e152b1327585d181ca`
- Rollback command / workflow: `git revert merge commit 1676a8a or redeploy previous validated rc baseline via release pipeline`
- RTO: `<= 30 minutes`
- Post-rollback checks: `panel0_linux_prod_readiness, console_linux_prod_readiness, snapshot/stream consistency`
- Rollback owner: `neo-2022`

## 7. Evidence
- CI run URL: `https://github.com/neo-2022/Art/pull/20/checks`
- Release artifacts: `docs/governance/evidence/*, artifacts/platform-evidence/*`
- SBOM / checksums: `validated by release-signing-verify and stage37 contract gates`
- Runtime logs: `docs/governance/evidence/stage37_stage_gate.log, docs/governance/evidence/stage37_docker_execute_smoke.log, docs/governance/evidence/stage37_k8s_execute_smoke.log, docs/governance/evidence/stage38_ladder_gate.log`
- Screenshots / reports: `docs/governance/evidence/stage32_step3_verify_ui.png, docs/governance/evidence/stage33_step7_action_flow_anti_breakage.png`
- Evidence IDs: `EVIDENCE_PLATFORM_MATRIX, EVIDENCE_CERTIFIED_BUILD, EVIDENCE_DOCKER_REPRODUCIBLE, EVIDENCE_REGART_INTEGRATION_UBUNTU_SMOKE`

## 8. Decision
- Decision: `GO`
- Rationale: `merged main baseline contains real execute-gated Docker and Kubernetes runtime validation, required checks passed, and stage24/stage37/stage38 governance gates remain green`
- Additional conditions: `stable production tag is still blocked until signed release tag and GitHub Release artifacts are published by CI`
- Next control checkpoint: `immediately before creating the signed v0.2.0 release tag`

## 9. Sign-off
- Release Manager: `neo-2022 / GO / 2026-03-06T17:05:38Z`
- Tech Lead: `neo-2022 / GO / 2026-03-06T17:05:38Z`
- SRE / Operations: `neo-2022 / GO / 2026-03-06T17:05:38Z`
- Security: `neo-2022 / GO / 2026-03-06T17:05:38Z`
- Product Owner (if required): `production tag pending signed artifact publication`
