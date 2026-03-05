#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CHECKLIST="$ROOT/docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md"
REGISTRY="$ROOT/docs/governance/observability_gap_registry.md"
RUNBOOK="$ROOT/docs/runbooks/ui_proxy_unavailable.md"
MY_AGENT_REPO="$ROOT/.tmp/my_langgraph_agent"
MY_AGENT_UI="$MY_AGENT_REPO/ui"
MY_AGENT_URL="https://github.com/neo-2022/my_langgraph_agent.git"

test -s "$CHECKLIST"
grep -q "multi-tab" "$CHECKLIST"
grep -q "ui.graph.empty" "$CHECKLIST"
grep -q "observability_gap.ui_proxy_unavailable" "$CHECKLIST"
grep -q "tests/multiTabManager.spec.js" "$CHECKLIST"
grep -q "tests/outbox.spec.js" "$CHECKLIST"
grep -q "tests/uiProxyGap.spec.js" "$CHECKLIST"
grep -q "ui/src/multiTabManager.js" "$CHECKLIST"
grep -q "ui/src/obs/uiProxyGap.js" "$CHECKLIST"
test -s "$RUNBOOK"
grep -q "observability_gap.ui_proxy_unavailable" "$RUNBOOK"
test -s "$REGISTRY"
grep -q "observability_gap.ui_proxy_unavailable" "$REGISTRY"

if [ ! -d "$MY_AGENT_UI" ]; then
  rm -rf "$MY_AGENT_REPO"
  git clone --depth 1 "$MY_AGENT_URL" "$MY_AGENT_REPO"
fi

test -s "$MY_AGENT_UI/package.json"

echo "installing ui dependencies for stage05"
npm --prefix "$MY_AGENT_UI" ci

echo "running ui tests for stage05"
npm --prefix "$MY_AGENT_UI" test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js tests/uiProxyGap.spec.js

echo "stage05 wrapper gate: OK"
