#!/usr/bin/env bash
set -euo pipefail
f=docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md
test -s "$f"
grep -q "CHECKLIST_REGART_ART_INTEGRATION.md" "$f"
grep -q "my_langgraph_agent" "$f"
test -s docs/regart/art_bridge_runbook.md
test -s docs/regart/upstream_error_format.md
echo "stage06 wrapper gate: OK"
