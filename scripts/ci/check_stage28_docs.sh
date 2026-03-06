#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/source/FOUNDATION_CONSTITUTION_V0_2.md"
  "docs/source/dna_core_determinism_performance_assurance.md"
  "docs/source/analytics_memory_v0_2.md"
  "docs/source/risk_register_v0_2.md"
  "docs/source/console_settings_architecture_v0_2.md"
  "docs/source/checklists/TRACEABILITY_V0_2.md"
  "docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md"
  "docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md"
  "docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md"
  "docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md"
  "docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md"
  "docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md"
  "docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md"
  "docs/source/checklists/CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md"
  "docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md"
  "docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md"
  "docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md"
  "docs/contracts/v2/openapi.yaml"
  "docs/contracts/v2/schemas/raw_event_v2.json"
  "docs/contracts/v2/schemas/dna_signature.json"
  "docs/contracts/v2/schemas/evidence_block.json"
  "docs/contracts/v2/schemas/claim_v2.json"
  "docs/contracts/v2/schemas/dialog_message_v2.json"
  "docs/contracts/v2/schemas/snapshot_v2.json"
  "docs/contracts/v2/contract_fingerprint.sha256"
  "docs/contracts/v2/migrations_v2.md"
  "docs/contracts/v2/dna_model/README.md"
  "docs/contracts/v2/dna_model/dna_core_clusterization.tla"
  "docs/contracts/v2/dna_model/dna_core_clusterization.cfg"
  "docs/source/investigations_as_code.md"
  "docs/source/audit_merkle_verify.md"
  "docs/source/secure_actions_protocol_v2.md"
  "docs/source/perf_load_coverage_v0_2.md"
  "docs/source/spatial_store_v0_2.md"
  "docs/source/saas_readiness_v0_2.md"
  "docs/ops/console_linux_prod_readiness.md"
  "docs/ops/art_regart_contract_parity.md"
  "docs/ops/operational_debt_register.md"
  "docs/ops/stage_ladder_enforcement.md"
  "docs/ops/runtime_incident_status.json"
  "docs/source/coverage_ratchet_baseline_v0_2.json"
  "scripts/tests/console_linux_prod_readiness.sh"
  "scripts/tests/stage34_perf_load_smoke.sh"
  "scripts/tests/dna_reference_impl.py"
  "scripts/ci/check_stage37_linux_hardening.sh"
  "scripts/ci/check_stage31_investigation_doc.sh"
  "scripts/ci/check_stage32_audit_merkle.sh"
  "scripts/ci/check_stage33_secure_actions.sh"
  "scripts/ci/check_stage35_spatial_readiness.sh"
  "scripts/ci/check_stage36_saas_architecture.sh"
  "scripts/ci/check_stage28_lens.sh"
  "scripts/ci/check_stage28_audio_settings.sh"
  "scripts/ci/check_v2_contract_fingerprint.sh"
  "scripts/ci/check_dna_assurance_program.sh"
  "scripts/ci/check_v0_2_risk_register.sh"
  "scripts/ci/run_stage29_dna_tests.sh"
  "scripts/ci/run_stage29_dna_property_million.sh"
  "scripts/ci/run_stage29_replay_determinism.sh"
  "scripts/tests/workspace_boundary_negative_smoke.sh"
  "scripts/tests/console_audio_settings_e2e.sh"
  "docs/runbooks/console_workspace_boundary_violation.md"
  "docs/runbooks/dna_signature_mismatch.md"
  "docs/runbooks/dna_determinism_violation.md"
  "docs/runbooks/dna_reference_mismatch.md"
  "docs/runbooks/dna_canary_divergence.md"
  "docs/runbooks/dna_replay_mismatch.md"
  "docs/runbooks/api_dual_write_mismatch.md"
  "docs/runbooks/ui_law_violation.md"
  "docs/runbooks/dna_traceability_gap.md"
  "docs/runbooks/local_store_latency_exceeded.md"
  "docs/runbooks/evidence_privacy_violation.md"
  "docs/runbooks/v2_migration_failed.md"
  "docs/runbooks/evidence_scope_violation.md"
  "docs/runbooks/claim_without_evidence.md"
  "docs/runbooks/investigation_replay_failed.md"
  "docs/runbooks/audit_merkle_verify_failed.md"
  "docs/runbooks/action_preflight_missing.md"
  "docs/runbooks/perf_budget_exceeded.md"
  "docs/runbooks/coverage_ratchet_failed.md"
  "docs/runbooks/innovation_experiment_regression.md"
  "docs/runbooks/spatial_index_degraded.md"
  "docs/runbooks/saas_tenant_isolation_failed.md"
  "docs/runbooks/console_linux_readiness_failed.md"
  "docs/runbooks/checklist_ladder_violation.md"
  "mkdocs.yml"
  "docs/portal/INDEX.md"
  "docs/portal/NAVIGATION.md"
  "docs/portal/DOC_STYLE_GUIDE.md"
  "docs/portal/DOC_AUTHORITY.md"
  "docs/portal/GLOSSARY.md"
  "docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md"
  "docs/portal/PRODUCT_GUARANTEES.md"
  "docs/portal/SECURITY_POSTURE.md"
  "docs/rag/README.md"
  "docs/rag/sources.yaml"
  "docs/rag/context_packs.md"
  "docs/rag/security_policy.md"
  "docs/en/README.md"
  "docs/en/ARCHITECTURE.md"
  "docs/en/INTEGRATION.md"
  "docs/en/portal/INDEX.md"
  "docs/en/portal/NAVIGATION.md"
  "docs/en/portal/DOC_STYLE_GUIDE.md"
  "docs/en/portal/DOC_AUTHORITY.md"
  "docs/en/portal/GLOSSARY.md"
  "docs/en/portal/COMPATIBILITY_MATRIX_ART_REGART.md"
  "docs/en/portal/PRODUCT_GUARANTEES.md"
  "docs/en/portal/SECURITY_POSTURE.md"
  "docs/en/rag/README.md"
  "docs/en/rag/context_packs.md"
  "docs/en/rag/security_policy.md"
  "docs/en/rag/sources.yaml"
  "scripts/ci/check_docs_portal_quality.sh"
)

for file in "${required_files[@]}"; do
  test -s "$file"
done

# Constitution and traceability sanity
grep -q "No checklist skipping" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "Observability Gap Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "DNA Engine Safety Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "Settings Information Architecture Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "stage38-ladder-gate" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "01..27 -> 28..38" docs/source/checklists/TRACEABILITY_V0_2.md

bash scripts/ci/check_stage28_lens.sh
bash scripts/ci/check_docs_portal_quality.sh

grep -q "CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md" docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md
grep -q "CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md" docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

for job in \
  stage28-lens-gate \
  stage28-audio-settings-e2e \
  docs-portal-gate \
  workspace-boundary-negative-smoke \
  stage29-contract-fingerprint \
  stage29-nightly-replay-determinism \
  stage31-investigation-doc-tests \
  stage32-audit-merkle-tests \
  stage33-secure-actions-tests \
  stage35-spatial-readiness-tests \
  stage36-saas-architecture-gate
  do
  grep -q "${job}:" .github/workflows/ci.yml
done

# Contracts sanity
grep -q "/api/v2/ingest" docs/contracts/v2/openapi.yaml
grep -q "/api/v2/dna/{dna_id}/similar" docs/contracts/v2/openapi.yaml
grep -q "/api/v2/evidence/{evidence_id}" docs/contracts/v2/openapi.yaml
grep -q "/api/v2/analytics/summary" docs/contracts/v2/openapi.yaml

grep -q "dna_schema_version" docs/contracts/v2/schemas/dna_signature.json
grep -q "access_scope" docs/contracts/v2/schemas/evidence_block.json
grep -q "proof_set" docs/contracts/v2/schemas/claim_v2.json
grep -q "ActionRequest" docs/contracts/v2/schemas/dialog_message_v2.json
grep -q "dna_clusters" docs/contracts/v2/schemas/snapshot_v2.json

# Checklist quality gates
bash scripts/ci/check_v0_2_checklists_quality.sh
bash scripts/ci/check_dna_assurance_program.sh
bash scripts/ci/check_v0_2_risk_register.sh

# Required v0.2 observability gap events in registry
for event in \
  observability_gap.console_workspace_boundary_violation \
  observability_gap.dna_signature_mismatch \
  observability_gap.dna_determinism_violation \
  observability_gap.dna_reference_mismatch \
  observability_gap.dna_canary_divergence \
  observability_gap.dna_replay_mismatch \
  observability_gap.api_dual_write_mismatch \
  observability_gap.ui_law_violation \
  observability_gap.dna_traceability_gap \
  observability_gap.local_store_latency_exceeded \
  observability_gap.evidence_privacy_violation \
  observability_gap.v2_migration_failed \
  observability_gap.evidence_scope_violation \
  observability_gap.claim_without_evidence \
  observability_gap.investigation_replay_failed \
  observability_gap.audit_merkle_verify_failed \
  observability_gap.action_preflight_missing \
  observability_gap.perf_budget_exceeded \
  observability_gap.coverage_ratchet_failed \
  observability_gap.innovation_experiment_regression \
  observability_gap.spatial_index_degraded \
  observability_gap.saas_tenant_isolation_failed \
  observability_gap.console_linux_readiness_failed \
  observability_gap.checklist_ladder_violation
  do
  grep -q "^| ${event} |" docs/governance/observability_gap_registry.md
done

echo "stage28 docs gate: OK"
