#!/usr/bin/env bash
set -euo pipefail
for f in docs/ops/deploy_systemd.md docs/ops/deploy_k8s.md docs/ops/tls_rotation.md docs/ops/db_migration_runbook.md docs/ops/backup_restore.md docs/ops/dr_drill.md docs/runbooks/tls_config_invalid.md; do
  test -s "$f"
done
grep -q "CORE_DB_PATH" docs/ops/deploy_systemd.md
grep -q "CORE_ANALYTICS_STATE_PATH" docs/ops/deploy_systemd.md
grep -q "cert-manager" docs/ops/deploy_k8s.md
grep -q "ClusterIssuer" docs/ops/deploy_k8s.md
grep -q "art-tls" docs/ops/deploy_k8s.md
grep -q "SIGHUP" docs/ops/tls_rotation.md
grep -q "stream" docs/ops/tls_rotation.md
grep -q "ops_stage23_smoke.sh" docs/ops/tls_rotation.md
grep -q "hot-reload" docs/ops/tls_rotation.md
grep -q "startup backlog" docs/ops/tls_rotation.md
grep -q "integrity" docs/ops/db_migration_runbook.md
grep -q "rollback" docs/ops/db_migration_runbook.md
grep -q "sqlite3" docs/ops/backup_restore.md
grep -q ".backup" docs/ops/backup_restore.md
grep -q "integrity" docs/ops/backup_restore.md
grep -q "CORE_DB_PATH" docs/ops/backup_restore.md
grep -q "snapshot" docs/ops/backup_restore.md
grep -q "audit" docs/ops/backup_restore.md
grep -q "analytics" docs/ops/backup_restore.md
grep -q "ingest" docs/ops/dr_drill.md
grep -q "snapshot" docs/ops/dr_drill.md
grep -q "pass/fail" docs/ops/dr_drill.md
grep -q "ops_stage23_smoke.sh" docs/ops/dr_drill.md
grep -q "audit" docs/ops/dr_drill.md
grep -q "analytics" docs/ops/dr_drill.md
grep -q "mitigations" docs/runbooks/tls_config_invalid.md
grep -q "verification" docs/runbooks/tls_config_invalid.md
grep -q "startup backlog" docs/runbooks/tls_config_invalid.md
grep -q "tls_config_invalid" docs/governance/observability_gap_registry.md
grep -q "cert_path" docs/governance/observability_gap_registry.md
grep -q "key_path" docs/governance/observability_gap_registry.md
grep -q "create_incident_min_sev1" docs/governance/observability_gap_registry.md
echo "stage23 docs gate: OK"
