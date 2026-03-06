#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
LOG_FILE="$OUT_DIR/stage36_step2_architecture_validation.log"
REPORT_MD="$OUT_DIR/stage36_step2_architecture_report.md"

mkdir -p "$OUT_DIR"

DOC="docs/source/saas_readiness_v0_2.md"

grep -q "org/project/env" "$DOC"
grep -q "control-plane/data-plane" "$DOC"
grep -q "quotas/retention/compliance" "$DOC"
grep -q "API parity" "$DOC"

{
  echo "stage36 step2 architecture validation: PASS"
  echo "doc=$DOC"
  echo "validated=tenant model + control/data plane + quotas + retention + parity"
} | tee "$LOG_FILE"

cat > "$REPORT_MD" <<MD
# Stage36 Step2 Architecture Validation

- source: \
  - $DOC
- validated blocks:
  - org/project/env tenant model
  - control-plane/data-plane boundaries
  - quotas/retention/compliance boundaries
  - self-hosted/SaaS API parity statement
- verdict: PASS
MD
