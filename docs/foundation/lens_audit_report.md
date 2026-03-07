# Lens Audit Report v0.2

Статус: ACTIVE
Последняя актуализация: 2026-03-06
Источник: `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)

## Правило чтения отчёта
- `Status: [x]` означает, что линза имеет достаточный набор артефактов, checklist mapping и воспроизводимую проверку в текущем scope.
- `Status: [ ]` означает, что линза признана обязательной или полезной, но в проекте остаётся блокирующий gap либо незавершённый контур внедрения.
- Для `Primary`-линз открытый gap считается блокирующим до его закрытия через checklist/gate/evidence.
- Для `Secondary`-линз gap фиксируется как backlog до момента, когда линза переводится в активный scope.
- Для `Anti-pattern`-линз фиксируются запреты и признаки риска; внедрение таких моделей запрещено.

## Классовые правила
- Primary: отсутствие артефактов = блокирующий gap.
- Secondary: gap фиксируется только если мы решили использовать линзу в текущем scope.
- Anti-pattern: фиксируются только признаки/риски, без плана внедрения как продуктовой возможности.

## Primary lenses

### Lens: Evidence/Assurance-driven (Evidence-first)
Class: Primary
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `packages/ui-laws/*`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять rule `claim without evidence = FAIL` как обязательный law-check для новых surface-компонентов.
Verification:
- `corepack pnpm --filter @art/ui-laws run test`
- `rg -n "Evidence-First|claim/hypothesis/recommendation запрещены без evidence_refs" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [x]

### Lens: Risk-driven
Class: Primary
Existing coverage:
- `docs/source/risk_register_v0_2.md`
- `scripts/ci/check_v0_2_risk_register.sh`
- `docs/governance/observability_gap_registry.md`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Поддерживать связь `risk -> gate -> observability_gap -> runbook` для новых этапов и новых production-рисков.
Verification:
- `bash scripts/ci/check_v0_2_risk_register.sh`
Checklist mapping:
- CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
- CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
- CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Status: [x]

### Lens: Constraint-driven (perf/security/offline)
Class: Primary
Existing coverage:
- `docs/source/perf_load_coverage_v0_2.md`
- `docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
- `docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
Gaps:
- Runtime-доказательство 3D/spatial части пока слабее документального контура.
Fix plan:
- Закрыть spatial/runtime gap без расширения scope beyond current contracts.
Verification:
- `bash scripts/ci/check_stage37_linux_hardening.sh`
- `bash scripts/ci/check_docs_master_traceability.sh`
Checklist mapping:
- CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
- CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
- CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
Status: [ ]

### Lens: Contract-first + Policy-first (Policy-as-UI)
Class: Primary
Existing coverage:
- `docs/contracts/v2/openapi.yaml`
- `docs/contracts/v2/schemas/*`
- `docs/source/secure_actions_protocol_v2.md`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять policy-as-ui через contract changes only, без UI-only truth.
Verification:
- `bash scripts/ci/check_contract_fingerprint.sh`
- `bash scripts/ci/check_stage28_docs.sh`
Checklist mapping:
- CHECKLIST_29_EVENT_DNA_CORE_V2.md
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
- CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
Status: [x]

### Lens: Architecture-first
Class: Primary
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `scripts/ci/check_workspace_boundaries.sh`
- `apps/console-web`, `packages/*`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Не допускать erosion границ monorepo за пределами workspace contracts.
Verification:
- `bash scripts/ci/check_workspace_boundaries.sh`
Checklist mapping:
- CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [x]

### Lens: Operations/SRE-driven
Class: Primary
Existing coverage:
- `docs/governance/slo_sli.md`
- `docs/runbooks/*`
- `docs/ops/go_no_go_template.md`
Gaps:
- `docs/ops/operational_debt_register.md` всё ещё содержит шаблонный placeholder вместо зрелого живого долга.
Fix plan:
- Заменить template debt на реальный operational backlog с owner/severity/ETA.
Verification:
- `rg -n "placeholder" docs/ops/operational_debt_register.md`
Checklist mapping:
- CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
- CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [ ]

### Lens: Quality-first (gates + real load tests)
Class: Primary
Existing coverage:
- `.github/workflows/ci.yml`
- `scripts/ci/*`
- `docs/governance/evidence/evidence_ledger.yaml`
Gaps:
- Часть stage31/32/33/35 контуров остаётся сильнее в governance/docs, чем в глубоком runtime-e2e.
Fix plan:
- Увеличивать долю runtime/integration suites на критичных путях при следующем цикле hardening.
Verification:
- `bash scripts/ci/check_stage_ladder_enforcement.sh`
- `bash scripts/ci/check_evidence_ledger.sh`
Checklist mapping:
- CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
- CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [ ]

### Lens: Security-first / Zero-trust
Class: Primary
Existing coverage:
- `docs/security/*`
- `docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
- `docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
Gaps:
- `docs/security/keys/cosign.pub` пока placeholder, а не реальный production public key.
Fix plan:
- Подменить placeholder реальным release-signing material и довести verify-chain до production state.
Verification:
- `rg -n "placeholder-public-key" docs/security/keys/cosign.pub`
Checklist mapping:
- CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md
- CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
- CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Status: [ ]

### Lens: Privacy-by-Design
Class: Primary
Existing coverage:
- `docs/privacy/*`
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять запрет утечки секретов в local index и derived stores.
Verification:
- `corepack pnpm run console:test`
Checklist mapping:
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [x]

### Lens: Supply-chain security
Class: Primary
Existing coverage:
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/security/provenance_signing.md`
Gaps:
- `docs/security/allowlist.gitleaks.toml` содержит placeholder-allowlist.
- release signing chain ещё не выглядит финально production-grade.
Fix plan:
- Убрать placeholder allowlist и перевести signing/allowlist политику в реальный production baseline.
Verification:
- `rg -n "placeholder" docs/security/allowlist.gitleaks.toml docs/security/keys/cosign.pub`
Checklist mapping:
- CHECKLIST_04 _Secure SDLC + Supply-chain.md
- CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md
- CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Status: [ ]

### Lens: Platform/Composable
Class: Primary
Existing coverage:
- `apps/console-web`
- `packages/*`
- `scripts/ci/check_workspace_boundaries.sh`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять композиционную модель и не смешивать `browser/` с `apps/console-web`.
Verification:
- `bash scripts/ci/check_workspace_boundaries.sh`
Checklist mapping:
- CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [x]

### Lens: Human-centered
Class: Primary
Existing coverage:
- `packages/ui-laws`
- `packages/i18n`
- `browser/test/panel0_i18n_laws.test.js`
- `apps/console-web/test/console-web.test.mjs`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять `tooltip everywhere`, `one-click-to-evidence`, EN/RU и accessibility baseline.
Verification:
- `corepack pnpm run console:test`
- `node --test browser/test/panel0_i18n_laws.test.js`
Checklist mapping:
- CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [x]

### Lens: Data/Index-first
Class: Primary
Existing coverage:
- `packages/local-stores`
- `docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Gaps:
- Spatial/local-stores часть всё ещё неравномерна: часть контракта есть, часть runtime остаётся stubbed/упрощённой.
Fix plan:
- Довести local-stores spatial path до состояния без `stubbed` contract markers.
Verification:
- `rg -n 'stubbed' packages/local-stores`
Checklist mapping:
- CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
- CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
Status: [ ]

### Lens: Streaming-first + Backpressure-first
Class: Primary
Existing coverage:
- `docs/source/checklists/CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
- `docs/source/checklists/CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md`
- `docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять ingest/stream laws как базу для DNA/Console derived layers.
Verification:
- `bash scripts/ci/check_docs_master_traceability.sh`
Checklist mapping:
- CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md
- CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md
- CHECKLIST_29_EVENT_DNA_CORE_V2.md
Status: [x]

### Lens: Audit-first (Merkle verify + immutable audit)
Class: Primary
Existing coverage:
- `docs/source/audit_merkle_verify.md`
- `docs/governance/audit_policy.md`
- `docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять verify-path из Incident Room, Investigation Library и Flow contexts.
Verification:
- `bash scripts/ci/check_docs_master_traceability.sh`
Checklist mapping:
- CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
Status: [x]

## Secondary lenses

### Lens: Scientific / Hypothesis-driven
Class: Secondary
Existing coverage:
- `docs/source/dna_core_determinism_performance_assurance.md`
- `docs/foundation/revolutionary_hypotheses.md`
Gaps:
- До текущего remediation hypothesis backlog был слабо привязан к checklist mapping.
Fix plan:
- Держать все экспериментальные треки в управляемом R&D backlog с adoption gate.
Verification:
- `test -s docs/foundation/revolutionary_hypotheses.md`
Checklist mapping:
- CHECKLIST_29_EVENT_DNA_CORE_V2.md
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
- CHECKLIST_31_INVESTIGATIONS_AS_CODE.md
- CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
- CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Status: [x]

### Lens: Model-driven
Class: Secondary
Existing coverage:
- `docs/contracts/v2/dna_model/*`
- `docs/contracts/v2/schemas/*`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Использовать model-driven подход только там, где он реально усиливает determinism/contracts.
Verification:
- `bash scripts/ci/check_contract_fingerprint.sh`
Checklist mapping:
- CHECKLIST_29_EVENT_DNA_CORE_V2.md
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [x]

### Lens: Formal/Correctness-driven
Class: Secondary
Existing coverage:
- `docs/contracts/v2/dna_model/*`
- `docs/source/dna_core_determinism_performance_assurance.md`
Gaps:
- Formal контур явно силён для DNA, но не доведён до такого же уровня в других критичных протоколах.
Fix plan:
- Расширять formal scope точечно: DNA, audit proofs, critical action protocol.
Verification:
- `test -d docs/contracts/v2/dna_model`
Checklist mapping:
- CHECKLIST_29_EVENT_DNA_CORE_V2.md
- CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
Status: [ ]

### Lens: Economics-driven
Class: Secondary
Existing coverage:
- `docs/source/saas_readiness_v0_2.md`
- `docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
Gaps:
- Контур cost/quotas/billing описан архитектурно, но не operationally proved.
Fix plan:
- Оставить как architecture/readiness layer до следующего цикла SaaS implementation.
Verification:
- `test -s docs/source/saas_readiness_v0_2.md`
Checklist mapping:
- CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md
Status: [ ]

### Lens: Stage-Gate
Class: Secondary
Existing coverage:
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `scripts/ci/check_stage_ladder_enforcement.sh`
Gaps:
- Нет блокирующих gap в текущем scope.
Fix plan:
- Сохранять stage-gate как governance-рамку, не превращая её в замену инженерной работы.
Verification:
- `bash scripts/ci/check_stage_ladder_enforcement.sh`
Checklist mapping:
- CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [x]

## Anti-pattern lenses

### Lens: Code-and-Fix / Big-bang
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
Gaps:
- Нет gap на уровне policy: подход прямо запрещён.
Fix plan:
- Не применять.
Verification:
- `rg -n "Code-and-Fix|Big-bang" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [x]

### Lens: RAD как "ускорение за счёт упрощений"
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
Gaps:
- Нет gap на уровне policy: допускается только timeboxing без снижения качества/безопасности.
Fix plan:
- Не применять как модель упрощения требований.
Verification:
- `rg -n "Timeboxing \(без снижения требований качества/безопасности\)" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [x]

### Lens: AI-first без evidence
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
- `packages/ui-laws`
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
Gaps:
- Нет блокирующих gap в текущем scope: claim без evidence уже запрещён.
Fix plan:
- Не применять AI-paths, нарушающие Evidence-First law.
Verification:
- `rg -n "claims без evidence_refs|Evidence-anchored AI" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `corepack pnpm --filter @art/ui-laws run test`
Checklist mapping:
- CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [x]
