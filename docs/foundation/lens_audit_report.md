# Lens Audit Report v0.2

Статус: ACTIVE
Последняя актуализация: 2026-03-06
Источник: `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)

## Классовые правила
- Primary: отсутствие артефактов = блокирующий gap.
- Secondary: gap фиксируется только если мы решили использовать линзу в текущем scope.
- Anti-pattern: фиксируются только признаки/риски, без плана внедрения.

## Primary lenses

### Lens: Evidence/Assurance-driven (Evidence-first)
Class: Primary
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [ ]

### Lens: Risk-driven
Class: Primary
Existing coverage:
- `docs/source/risk_register_v0_2.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [ ]

### Lens: Constraint-driven (perf/security/offline)
Class: Primary
Existing coverage:
- `docs/source/perf_load_coverage_v0_2.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Status: [ ]

### Lens: Contract-first + Policy-first (Policy-as-UI)
Class: Primary
Existing coverage:
- `docs/contracts/v2/openapi.yaml`
- `docs/contracts/v2/schemas/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_29_EVENT_DNA_CORE_V2.md
Status: [ ]

### Lens: Architecture-first
Class: Primary
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [ ]

### Lens: Operations/SRE-driven
Class: Primary
Existing coverage:
- `docs/governance/slo_sli.md`
- `docs/runbooks/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Status: [ ]

### Lens: Quality-first (gates + real load tests)
Class: Primary
Existing coverage:
- `.github/workflows/ci.yml`
- `scripts/ci/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Status: [ ]

### Lens: Security-first / Zero-trust
Class: Primary
Existing coverage:
- `docs/security/*`
- `docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
Status: [ ]

### Lens: Privacy-by-Design
Class: Primary
Existing coverage:
- `docs/privacy/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [ ]

### Lens: Supply-chain security
Class: Primary
Existing coverage:
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Status: [ ]

### Lens: Platform/Composable
Class: Primary
Existing coverage:
- `apps/console-web`
- `packages/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [ ]

### Lens: Human-centered
Class: Primary
Existing coverage:
- `packages/ui-laws`
- `browser/test/panel0_i18n_laws.test.js`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [ ]

### Lens: Data/Index-first
Class: Primary
Existing coverage:
- `packages/local-stores`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
Status: [ ]

### Lens: Streaming-first + Backpressure-first
Class: Primary
Existing coverage:
- `docs/source/checklists/CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md`
- `docs/source/checklists/CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_29_EVENT_DNA_CORE_V2.md
Status: [ ]

### Lens: Audit-first (Merkle verify + immutable audit)
Class: Primary
Existing coverage:
- `docs/source/audit_merkle_verify.md`
- `docs/governance/audit_policy.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
Status: [ ]

## Secondary lenses

### Lens: Scientific / Hypothesis-driven
Class: Secondary
Existing coverage:
- `docs/source/dna_core_determinism_performance_assurance.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
Status: [ ]

### Lens: Model-driven
Class: Secondary
Existing coverage:
- `docs/contracts/v2/dna_model/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_29_EVENT_DNA_CORE_V2.md
Status: [ ]

### Lens: Formal/Correctness-driven
Class: Secondary
Existing coverage:
- `docs/contracts/v2/dna_model/*`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_29_EVENT_DNA_CORE_V2.md
Status: [ ]

### Lens: Economics-driven
Class: Secondary
Existing coverage:
- `docs/source/saas_readiness_v0_2.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md
Status: [ ]

### Lens: Stage-Gate
Class: Secondary
Existing coverage:
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
Gaps:
- [ ]
Fix plan:
- [ ]
Verification:
- [ ]
Checklist mapping:
- [ ] CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [ ]

## Anti-pattern lenses

### Lens: Code-and-Fix / Big-bang
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
Gaps:
- [ ] Нет автоматической проверки признаков anti-pattern в review checklist.
Fix plan:
- Запретить через policy и code review правила; внедрение anti-pattern не допускается.
Verification:
- `rg -n "Code-and-Fix|Big-bang" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- [ ] CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Status: [ ]

### Lens: RAD как "ускорение за счёт упрощений"
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
Gaps:
- [ ] Нет отдельного review-rule для отклонения упрощений качества/безопасности.
Fix plan:
- Разрешён только Timeboxing без снижения требований.
Verification:
- `rg -n "Timeboxing \(без снижения требований качества/безопасности\)" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- [ ] CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Status: [ ]

### Lens: AI-first без evidence
Class: Anti-pattern
Existing coverage:
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` (APPENDIX A)
Gaps:
- [ ] Нет единого CI-check на нарушение evidence-anchored claims.
Fix plan:
- Внедрить runtime/CI law-check, что claim без `evidence_refs` блокируется.
Verification:
- `rg -n "AI не имеет права генерировать claims без evidence_refs" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
Checklist mapping:
- [ ] CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Status: [ ]
