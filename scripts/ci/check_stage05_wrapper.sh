#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHECKLIST="$ROOT/docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md"
REGISTRY="$ROOT/docs/governance/observability_gap_registry.md"
RUNBOOK="$ROOT/docs/runbooks/ui_proxy_unavailable.md"

# strict=1: validate external source-of-truth repository and run its UI tests.
# strict=0: validate only local wrapper + local runtime tests (default for CI stability).
STRICT_MODE_RAW="${STAGE05_EXTERNAL_STRICT:-auto}"
if [[ "$STRICT_MODE_RAW" == "auto" ]]; then
  if [[ -n "${MY_LANGGRAPH_AGENT_DIR:-}" ]] || [[ -d "$ROOT/../my_langgraph_agent" ]]; then
    STRICT_EXTERNAL=1
  else
    STRICT_EXTERNAL=0
  fi
elif [[ "$STRICT_MODE_RAW" == "1" || "$STRICT_MODE_RAW" == "true" ]]; then
  STRICT_EXTERNAL=1
else
  STRICT_EXTERNAL=0
fi

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

if [[ "$STRICT_EXTERNAL" -eq 1 ]]; then
  if [[ -n "${MY_LANGGRAPH_AGENT_DIR:-}" ]]; then
    EXT_REPO="$MY_LANGGRAPH_AGENT_DIR"
  elif [[ -d "$ROOT/../my_langgraph_agent" ]]; then
    EXT_REPO="$ROOT/../my_langgraph_agent"
  else
    echo "stage05: strict mode requires local my_langgraph_agent checkout"
    exit 1
  fi

  EXT_CHECKLIST="$EXT_REPO/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md"
  EXT_UI="$EXT_REPO/ui"
  test -s "$EXT_CHECKLIST"
  test -s "$EXT_UI/package.json"

  if ! git -C "$EXT_REPO" rev-parse HEAD >/dev/null 2>&1; then
    echo "stage05: external REGART source must be a git checkout with pinned commit"
    exit 1
  fi
  EXT_COMMIT="$(git -C "$EXT_REPO" rev-parse HEAD)"
  if [[ -n "$(git -C "$EXT_REPO" status --porcelain)" ]]; then
    echo "stage05: external REGART source must be clean; dirty checkout is forbidden"
    exit 1
  fi
  echo "stage05: pinned external source commit $EXT_COMMIT"

  echo "stage05: install external ui dependencies"
  npm --prefix "$EXT_UI" ci

  echo "stage05: run external source-of-truth tests"
  npm --prefix "$EXT_UI" test -- --run tests/multiTabManager.spec.js tests/outbox.spec.js tests/uiProxyGap.spec.js
else
  LOCAL_UI="$ROOT/browser"
  test -s "$LOCAL_UI/package.json"
  test -s "$LOCAL_UI/test/multitab.e2e.test.js"
  test -s "$LOCAL_UI/test/outbox.compression.test.js"

  echo "stage05: install local browser dependencies"
  npm --prefix "$LOCAL_UI" ci

  echo "stage05: run local runtime wrapper smoke tests"
  npm --prefix "$LOCAL_UI" test -- test/multitab.e2e.test.js test/outbox.compression.test.js
fi

bash "$ROOT/scripts/ci/check_regart_adversarial_harness.sh"

echo "stage05 wrapper gate: OK"
