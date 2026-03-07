# GO/NO-GO DECISION SHEET

## Source of truth
- `docs/ops/go_no_go_template.md`
- `docs/release/release_process.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/regart_adversarial_integration_harness_v0_2.md`

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
- [ ] `trust boundary` proof attached for privileged rollout
- [ ] `browser surface` baseline attached for browser-facing rollout
- [ ] `ingress/perimeter` baseline attached for internet-exposed rollout
- [ ] pinned external adversarial harness proof attached for partner-exposed / `REGART` rollout

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
- Open blockers: `missing trust boundary proof, missing browser surface proof, missing ingress/perimeter proof, missing pinned external adversarial harness proof for target rollout profile`
- Accepted risks with owner: `natural VM and non-Ubuntu native matrix remain validate-only until dedicated runners are enabled with ENABLE_NATURAL_MATRIX=true; owner neo-2022`
- Immediate STOP rollout condition: `any required gate fail, any active divergence incident, any Docker/Kubernetes execute smoke regression, any release-blocker in risk register`
- Additional STOP rollout condition: `missing or degraded trust boundary, missing browser surface baseline, degraded ingress/perimeter shield, missing pinned external adversarial harness evidence`
- Is a manual watch window required: `yes, for production rollout`

## 5. Rollout plan
- Step 1: `freeze merged main baseline and refresh release metadata for rc.2`
- PASS criteria for step 1: `release checklist, changelog, and production-candidate GO/NO-GO reference the merged main commit`
- Step 2: `validate mandatory execute-gated surfaces: Ubuntu native, Docker runtime, Kubernetes runtime`
- PASS criteria for step 2: `stage37 and platform runtime compatibility gates remain green with execute smoke evidence`
- Step 3: `create signed release tag and publish release artifacts through CI`
- PASS criteria for step 3: `stage24/stage37 gates, release signing verification, and artifact publication remain green`
- Step 4: `confirm trust boundary, browser surface, ingress/perimeter and pinned external adversarial harness evidence for target rollout profile`
- PASS criteria for step 4: `GO/NO-GO references trust boundary, browser surface, ingress/perimeter and harness proof and no protective contour blocker remains`
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
- Decision: `NO-GO`
- Rationale: `protective contours введены как обязательные release blockers, но доказательства trust boundary, browser surface, ingress/perimeter shield и pinned external adversarial harness для target rollout profile ещё не приложены`
- Additional conditions: `после появления этих доказательств решение может быть пересмотрено, но до этого ни stable production tag, ни privileged/internet-exposed, ни partner-exposed/REGART rollout недопустимы`
- Next control checkpoint: `после публикации protective evidence и повторного review release sheet`

## 9. Sign-off
- Release Manager: `neo-2022 / NO-GO / 2026-03-06T17:05:38Z`
- Tech Lead: `neo-2022 / NO-GO / 2026-03-06T17:05:38Z`
- SRE / Operations: `neo-2022 / NO-GO / 2026-03-06T17:05:38Z`
- Security: `neo-2022 / NO-GO / 2026-03-06T17:05:38Z`
- Product Owner (if required): `production rollout blocked by missing protective evidence`
