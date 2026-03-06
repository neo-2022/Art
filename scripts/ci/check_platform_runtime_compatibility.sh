#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

YAML_FILE="formats/platform_support.yaml"
RU_DOC="docs/ops/platform-runtime-compatibility-matrix.md"
EN_DOC="docs/en/ops/platform-runtime-compatibility-matrix.md"

test -s "$YAML_FILE"
for doc in "$RU_DOC" "$EN_DOC"; do
  test -s "$doc"
  grep -q '^## Source of truth' "$doc"
  grep -q 'Release blocker' "$doc" || grep -q 'Release blockers' "$doc"
  grep -q 'ENABLE_NATURAL_MATRIX=false' "$doc"
done

grep -q '^runtime_compatibility_matrix:' "$YAML_FILE"
for key in linux_kernel systemd docker_engine kubernetes kind k3d; do
  grep -q "^    ${key}:" "$YAML_FILE"
done

grep -q '^  release_blockers:' "$YAML_FILE"
grep -q '^  mandatory_k8s_production_scenarios:' "$YAML_FILE"

for scenario in tls_ingress_path persistent_storage_recovery rolling_update_zero_downtime node_pressure_and_drain_recovery rbac_policy_audit_enforcement; do
  grep -q "${scenario}" "$YAML_FILE"
done

echo "platform runtime compatibility gate: OK"
