# Индекс чек-листов

Этот каталог содержит полный набор чек-листов `CHECKLIST_00..45`.

## Мастер и управление

- `CHECKLIST_00_MASTER_ART_REGART.md` — мастер-чеклист программы Art+REGART.
- `CHECKLIST_01_GOVERNANCE_SRE.md` — governance/SRE.
- `CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md` — privacy baseline (global).
- `CHECKLIST_03_REGIONAL_PROFILES.md` — региональные профили (global/eu/ru/air-gapped).
- `CHECKLIST_04 _Secure SDLC + Supply-chain.md` — secure SDLC и supply-chain.

## REGART readiness

- `CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md` — readiness UI/Graph/Run/Debugger.
- `CHECKLIST_06_REGART_ART_BRIDGE.md` — readiness bridge REGART → Art.
- Источник правды для деталей реализации 05/06 находится в репозитории REGART:
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`

## Art platform (Core/Contracts/Panel0)

- `CHECKLIST_07_ART_REPO_CI_DOCS.md` — репозиторий, CI, документация.
- `CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md` — контракты, OpenAPI, codegen.
- `CHECKLIST_09_TELEMETRY_OTEL_OTLP.md` — telemetry alignment OTel/OTLP.
- `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md` — browser Level0 (универсальный).
- `CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md` — storage SQLite.
- `CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md` — ingest ack/seq/backpressure.
- `CHECKLIST_13_ART_CORE_PIPELINE_ENRICH_RULES.md` — pipeline/rules/enrich.
- `CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md` — stream/snapshot/SSE.
- `CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md` — actions/audit/RBAC/PII.
- `CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md` — embedded Panel 0.

## Agent и интеграционные пакеты

- `CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md` — spool/outbox.
- `CHECKLIST_18_ART_AGENT_RECEIVERS.md` — receivers.
- `CHECKLIST_19_PACKS_FRAMEWORK.md` — framework паков.
- `CHECKLIST_20_PACK_REGART.md` — pack REGART.

## Эксплуатация, релизы, соответствие

- `CHECKLIST_21_SELF_OBSERVABILITY_ART.md` — self-observability Art.
- `CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md` — E2E/stress/chaos/soak/perf.
- `CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md` — ops/deploy/runbooks/DR.
- `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md` — release/upgrade/regression.
- `CHECKLIST_25_COMPLIANCE_AUDIT_READY.md` — compliance/audit readiness.
- `CHECKLIST_26_RU_PROFILE.md` — RU профиль (152-ФЗ/локализация/экспорт/аудит/air-gapped).
- `CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md` — итоговый аудит закрытия этапов и план/факт ремедиации.

## Программа v0.2 (Console + API v2) и continuation backlog

Важное правило программы:
- утверждённые differentiators и концепции из historical/foundation корпуса должны начинать встраиваться уже в этапы `01..38`, если они влияют на соответствующую подсистему;
- этапы `39..45` не являются “первым местом появления” этих идей;
- этапы `39..45` служат для специализированной финализации, hardening, отдельных CI-gates и production-grade доведения.

- `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md` — foundation Console в monorepo (apps+packages).
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md` — API v2 Event DNA core (formal model + property 1M + reference parity).
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md` — Evidence/Claims/Dialogic v2.
- `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md` — Investigations-as-Code.
- `CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md` — Audit + Merkle verify.
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md` — secure actions protocol v2.
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md` — perf/load/coverage ratchet (10k/100k + 5% perf guard).
- `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md` — spatial store + 3D readiness.
- `CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md` — SaaS readiness architecture.
- `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md` — Linux prod hardening Tier A/B (canary divergence stop + feature-flag fallback).
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md` — enforcement правила “лестницы” этапов.
- `CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md` — enforceable AI engineering governance и truthfulness gate.
- `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md` — brand/showcase layer и client-facing demo contour.
- `CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md` — AST/static UI laws и self-healing docs/tests automation.
- `CHECKLIST_42_EVIDENCE_INTELLIGENCE_AND_DRIFT.md` — Proof Completeness Score, DNA Drift Radar, Proof-Carrying AI Claims.
- `CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md` — Counterfactual Action Simulator, NRAC maturation, Wasm sandbox.
- `CHECKLIST_44_INCIDENT_CAPSULE_AND_TWIN.md` — Reproducible Incident Capsule и Deterministic Incident Twin.
- `CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md` — eBPF evidence linking, graph-backed exploration, future-safe crypto extension path.
- `TRACEABILITY_V0_2.md` — трассировка baseline 01..27 к новой программе 28..45.
- `../risk_register_v0_2.md` — принятые риски v0.2, контрмеры, release blockers.

## Порядок прохождения

1. `00`
2. `01..04`
3. `05..06`
4. `07..20`
5. `21..26`
6. `27`
7. `28..45`
