#!/usr/bin/env bash
set -euo pipefail

RISK_DOC="docs/source/risk_register_v0_2.md"

test -s "$RISK_DOC"

for risk_id in R1 R2 R3 R5 R8 R9 R10; do
  grep -q "| ${risk_id} |" "$RISK_DOC"
done

for blocker in \
  "forbidden-import-count > 0" \
  "normalized mismatch rate > 0" \
  "critical UI-law violation count > 0" \
  "trace unavailable for critical incident" \
  "p95 local-store latency > budget" \
  "unauthorized evidence access > 0" \
  "picking p95 > threshold"
  do
  grep -q "$blocker" "$RISK_DOC"
done

grep -q "normalized mismatch rate > 0" "$RISK_DOC"
grep -q "delivery_lag_grace_window" "$RISK_DOC"
grep -q "30 дней" "$RISK_DOC"
grep -q "90 дней" "$RISK_DOC"
grep -q "365+ дней" "$RISK_DOC"
grep -q "72 часов" "$RISK_DOC"
grep -q "Intel UHD 620" "$RISK_DOC"
grep -q "p95 latency < 50 ms" "$RISK_DOC"
grep -q "авто-деградация качества" "$RISK_DOC"

for event in \
  observability_gap.console_workspace_boundary_violation \
  observability_gap.api_dual_write_mismatch \
  observability_gap.ui_law_violation \
  observability_gap.dna_traceability_gap \
  observability_gap.local_store_latency_exceeded \
  observability_gap.evidence_privacy_violation \
  observability_gap.spatial_index_degraded
  do
  grep -q "^| ${event} |" docs/governance/observability_gap_registry.md
done

grep -q "stage28-risk-gate" .github/workflows/ci.yml

echo "v0.2 risk register gate: OK"
