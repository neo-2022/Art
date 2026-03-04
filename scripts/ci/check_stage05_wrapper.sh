#!/usr/bin/env bash
set -euo pipefail
f=docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md
test -s "$f"
grep -q "CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md" "$f"
grep -q "my_langgraph_agent" "$f"
test -s docs/runbooks/ui_proxy_unavailable.md
echo "stage05 wrapper gate: OK"
