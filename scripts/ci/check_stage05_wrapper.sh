#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CHECKLIST="$ROOT/docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md"
REGISTRY="$ROOT/docs/governance/observability_gap_registry.md"
RUNBOOK="$ROOT/docs/runbooks/ui_proxy_unavailable.md"
MY_AGENT_UI="$ROOT/../my_langgraph_agent/ui"

test -s "$CHECKLIST"
grep -q "multi-tab" "$CHECKLIST"
grep -q "observability_gap.ui_proxy_unavailable" "$CHECKLIST"
grep -q "tests/multiTabManager.spec.js" "$CHECKLIST"
grep -q "tests/outbox.spec.js" "$CHECKLIST"
grep -q "tests/uiProxyGap.spec.js" "$CHECKLIST"
test -s "$RUNBOOK"
grep -q "observability_gap.ui_proxy_unavailable" "$RUNBOOK"
test -s "$REGISTRY"
grep -q "observability_gap.ui_proxy_unavailable" "$REGISTRY"

echo "running ui tests for stage05"
npm --prefix "$MY_AGENT_UI" test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js tests/uiProxyGap.spec.js

echo "stage05 wrapper gate: OK"
