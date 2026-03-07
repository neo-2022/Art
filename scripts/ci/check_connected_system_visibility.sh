#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

for f in \
  docs/source/connected_system_visibility_v0_2.md \
  formats/connected_system_visibility_v0_2.yaml \
  docs/packs/source_coverage.md \
  docs/runbooks/connected_system_not_visible.md \
  docs/agent/receiver_source_coverage.md \
  docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md \
  docs/source/checklists/CHECKLIST_19_PACKS_FRAMEWORK.md \
  docs/source/checklists/CHECKLIST_20_PACK_REGART.md \
  docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md \
  packs/regart/manifest.yaml \
  packs/regart/signatures/manifest.sha256 \
  scripts/tests/test_connected_system_visibility.py; do
  test -s "$f"
done

python3 -m unittest scripts.tests.test_connected_system_visibility -v >/dev/null
(cd packs/regart && sha256sum -c signatures/manifest.sha256 >/dev/null)

grep -q "Connected System Visibility Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "Connected System Visibility" docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md
grep -q "Connected System View" docs/source/connected_system_visibility_v0_2.md
grep -q "declared_data_kinds" docs/source/connected_system_visibility_v0_2.md
grep -q "observed_data_kinds" docs/source/connected_system_visibility_v0_2.md
grep -q "service_inventory" docs/packs/source_coverage.md
grep -q "telemetry_endpoints" docs/packs/source_coverage.md
grep -q "connected_system_projection" docs/packs/source_coverage.md
grep -q "regart-browser-level0" docs/packs/source_coverage.md
grep -q "regart-ui-proxy" docs/packs/source_coverage.md
grep -q "regart-langgraph-runtime" docs/packs/source_coverage.md
grep -q "produced_data_kinds" docs/agent/receiver_source_coverage.md
grep -q "connected_system_projection" docs/agent/receiver_source_coverage.md
grep -q "Connected System View" docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md
grep -q "connected_system_projection" docs/source/checklists/CHECKLIST_19_PACKS_FRAMEWORK.md
grep -q "connected_system_projection" docs/source/checklists/CHECKLIST_20_PACK_REGART.md
grep -q "Connected System View" docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
grep -q "declared_only" docs/source/connected_system_visibility_v0_2.md
grep -q "disconnected" docs/source/connected_system_visibility_v0_2.md
grep -q "unknown" docs/source/connected_system_visibility_v0_2.md

for event in \
  observability_gap.connected_system_not_visible \
  observability_gap.connected_system_coverage_drift; do
  grep -q "^| ${event} |" docs/governance/observability_gap_registry.md
done

grep -q "service_inventory" packs/regart/manifest.yaml
grep -q "signal_coverage_claims" packs/regart/manifest.yaml
grep -q "telemetry_endpoints" packs/regart/manifest.yaml
grep -q "connected_system_projection" packs/regart/manifest.yaml
grep -q "freshness_threshold_ms" packs/regart/manifest.yaml
grep -q "regart-browser-level0" packs/regart/manifest.yaml
grep -q "regart-ui-proxy" packs/regart/manifest.yaml
grep -q "regart-langgraph-runtime" packs/regart/manifest.yaml

echo "connected system visibility gate: OK"
