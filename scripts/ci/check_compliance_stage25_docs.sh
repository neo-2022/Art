#!/usr/bin/env bash
set -euo pipefail
for f in docs/compliance/control_matrix.md docs/compliance/evidence_list.md docs/compliance/audit_trail.md docs/compliance/data_destruction.md docs/runbooks/export_failed.md scripts/export_audit_pack.sh; do
  test -s "$f"
done
grep -q "raw_archive" docs/compliance/evidence_list.md
grep -q "append-only" docs/compliance/evidence_list.md
grep -q "control_id" docs/compliance/control_matrix.md
grep -q "evidence_ref" docs/compliance/control_matrix.md
grep -q "review_frequency" docs/compliance/control_matrix.md
grep -q "export_audit_pack.sh" docs/compliance/audit_trail.md
grep -q "checksums.txt" docs/compliance/audit_trail.md
grep -q "stop" docs/compliance/data_destruction.md
grep -q "backup" docs/compliance/data_destruction.md
grep -q "pass/fail" docs/compliance/data_destruction.md
grep -q "mitigations" docs/runbooks/export_failed.md
grep -q "verification" docs/runbooks/export_failed.md
grep -q "export_failed" docs/governance/observability_gap_registry.md
grep -q "/api/v1/incidents" scripts/export_audit_pack.sh
grep -q "/api/v1/audit" scripts/export_audit_pack.sh
grep -q "checksums.txt" scripts/export_audit_pack.sh
echo "stage25 docs gate: OK"
