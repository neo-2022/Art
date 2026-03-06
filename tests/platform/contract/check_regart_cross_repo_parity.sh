#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="artifacts/regart-parity"
mkdir -p "$OUT_DIR"

UI_URL="https://raw.githubusercontent.com/neo-2022/my_langgraph_agent/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md"
BRIDGE_URL="https://raw.githubusercontent.com/neo-2022/my_langgraph_agent/main/CHECKLIST_REGART_ART_INTEGRATION.md"
UI_FILE="$OUT_DIR/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md"
BRIDGE_FILE="$OUT_DIR/CHECKLIST_REGART_ART_INTEGRATION.md"

curl -fsSL "$UI_URL" -o "$UI_FILE"
curl -fsSL "$BRIDGE_URL" -o "$BRIDGE_FILE"

# Contract anchors expected in external source-of-truth documents.
grep -qi "debugger" "$UI_FILE"
grep -qi "level" "$UI_FILE"
grep -qi "bridge" "$BRIDGE_FILE"
grep -qi "integration" "$BRIDGE_FILE"
grep -qi "tls\|https" "$BRIDGE_FILE"

# Internal wrappers must point to external SoT and master.
grep -q "CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md" docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md
grep -q "CHECKLIST_REGART_ART_INTEGRATION.md" docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md
grep -q "CHECKLIST_00_MASTER_ART_REGART.md" docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md
grep -q "CHECKLIST_00_MASTER_ART_REGART.md" docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md

ui_sha="$(sha256sum "$UI_FILE" | awk '{print $1}')"
bridge_sha="$(sha256sum "$BRIDGE_FILE" | awk '{print $1}')"
art_commit="$(git rev-parse --short HEAD)"
verification_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat > "$OUT_DIR/report.json" <<JSON
{
  "verification_date": "$verification_date",
  "art_commit": "$art_commit",
  "regart_ref": "main",
  "checks": {
    "ui_graph_run_debugger_sha256": "$ui_sha",
    "bridge_integration_sha256": "$bridge_sha"
  },
  "parity_result": "pass",
  "mismatches": []
}
JSON

echo "regart cross-repo parity: OK"
