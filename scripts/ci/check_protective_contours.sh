#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/source/trust_boundary_hardening_v0_2.md"
  "docs/source/browser_surface_hardening_v0_2.md"
  "docs/runbooks/trust_boundary_violation.md"
  "docs/runbooks/browser_surface_policy_degraded.md"
  "docs/testing/defect_remediation_control_matrix_v0_2.md"
  "formats/defect_remediation_control_matrix_v0_2.yaml"
)

for f in "${required_files[@]}"; do
  test -s "$f"
done

grep -q "Trust Boundary And Canonical Actor Context Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "Browser Surface Hardening Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "^| R15 |" docs/source/risk_register_v0_2.md
grep -q "^| R16 |" docs/source/risk_register_v0_2.md
grep -q "^| observability_gap.trust_boundary_violation |" docs/governance/observability_gap_registry.md
grep -q "^| observability_gap.browser_surface_policy_degraded |" docs/governance/observability_gap_registry.md
grep -q "DEF-019" docs/testing/defect_remediation_control_matrix_v0_2.md
grep -q "DEF-020" docs/testing/defect_remediation_control_matrix_v0_2.md
grep -q "id: DEF-019" formats/defect_remediation_control_matrix_v0_2.yaml
grep -q "id: DEF-020" formats/defect_remediation_control_matrix_v0_2.yaml
grep -q "docs/source/trust_boundary_hardening_v0_2.md" docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md
grep -q "docs/source/browser_surface_hardening_v0_2.md" docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md
grep -q "Trust boundary / canonical actor context" docs/source/checklists/TRACEABILITY_V0_2.md
grep -q "Browser surface hardening" docs/source/checklists/TRACEABILITY_V0_2.md

for checklist in \
  docs/source/checklists/CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md \
  docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md \
  docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md \
  docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md \
  docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md \
  docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md \
  docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md \
  docs/source/checklists/CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md
do
  test -s "$checklist"
done

grep -q "browser surface hardening" docs/source/checklists/CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md
grep -q "trust boundary" docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md
grep -q "browser surface hardening" docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
grep -q "trust boundary" docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md
grep -q "browser surface hardening" docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
grep -q "trust boundary" docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
grep -q "trust boundary" docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
grep -q "browser surface hardening" docs/source/checklists/CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md

echo "protective contours gate: OK"
