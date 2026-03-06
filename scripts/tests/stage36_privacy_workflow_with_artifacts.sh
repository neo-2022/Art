#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step4_privacy_workflow.log"
REPORT_MD="$OUT_DIR/stage36_step4_privacy_workflow_report.md"

mkdir -p "$OUT_DIR"

DOC="docs/source/saas_readiness_v0_2.md"
RISK="docs/source/risk_register_v0_2.md"

grep -q "30 дней" "$DOC"
grep -q "90 дней" "$DOC"
grep -q "365+" "$DOC"
grep -q "анонимизируется автоматически" "$DOC"
grep -q "72 часов" "$DOC"
grep -q "R9" "$RISK"
grep -q "observability_gap.evidence_privacy_violation" "$RISK"

{
  echo "stage36 step4 privacy workflow: PASS"
  echo "validated SLA: 30/90/365+ + auto-anonymization + remediation<=72h"
} | tee "$LOG_FILE"

cat > "$REPORT_MD" <<'MD'
# Stage36 Step4 Privacy Workflow Report

- SLA validated in `docs/source/saas_readiness_v0_2.md`:
  - operational retention: 30 days
  - incident retention: 90 days
  - compliance retention: 365+ days
  - long-term PII mode: auto-anonymization
  - remediation request SLA: <=72 hours
- risk register mapping: `R9` with `observability_gap.evidence_privacy_violation`
- verdict: PASS
MD
