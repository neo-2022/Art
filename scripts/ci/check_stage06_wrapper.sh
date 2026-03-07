#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ART_CHECKLIST="$ROOT/docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md"
RUNBOOK="$ROOT/docs/regart/art_bridge_runbook.md"
ERROR_FMT_DOC="$ROOT/docs/regart/upstream_error_format.md"

# External strict mode:
# - strict=1: enforce code-level checks in source-of-truth repo.
# - strict=0: enforce checklist/docs-level checks only.
# Auto mode enables strict only when local sibling repo is present.
STRICT_MODE_RAW="${STAGE06_EXTERNAL_STRICT:-auto}"
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

EXT_REPO=""
EXT_CHECKLIST=""
UI_PROXY=""
ITESTS=""
ITESTS_ACTIONS=""
if [[ "$STRICT_EXTERNAL" -eq 1 ]]; then
  if [[ -n "${MY_LANGGRAPH_AGENT_DIR:-}" ]]; then
    EXT_REPO="$MY_LANGGRAPH_AGENT_DIR"
  elif [[ -d "$ROOT/../my_langgraph_agent" ]]; then
    EXT_REPO="$ROOT/../my_langgraph_agent"
  else
    echo "stage06: strict mode requires local my_langgraph_agent checkout"
    exit 1
  fi
  EXT_CHECKLIST="$EXT_REPO/CHECKLIST_REGART_ART_INTEGRATION.md"
  UI_PROXY="$EXT_REPO/agent/src/react_agent/ui_proxy.py"
  ITESTS="$EXT_REPO/agent/tests/integration_tests/test_ui_art_ingest.py"
  ITESTS_ACTIONS="$EXT_REPO/agent/tests/integration_tests/test_ui_proxy_service_actions.py"
  if ! git -C "$EXT_REPO" rev-parse HEAD >/dev/null 2>&1; then
    echo "stage06: external REGART source must be a git checkout with pinned commit"
    exit 1
  fi
  EXT_COMMIT="$(git -C "$EXT_REPO" rev-parse HEAD)"
  if [[ -n "$(git -C "$EXT_REPO" status --porcelain)" ]]; then
    echo "stage06: external REGART source must be clean; dirty checkout is forbidden"
    exit 1
  fi
  echo "stage06: pinned external source commit $EXT_COMMIT"
fi

# Local wrapper docs must exist.
for f in "$ART_CHECKLIST" "$RUNBOOK" "$ERROR_FMT_DOC"; do
  test -s "$f"
done

if [[ "$STRICT_EXTERNAL" -eq 1 ]]; then
  test -s "$EXT_CHECKLIST"
  for f in "$UI_PROXY" "$ITESTS" "$ITESTS_ACTIONS"; do
    test -s "$f"
  done
fi

# Wrapper must explicitly reference source-of-truth.
grep -q "CHECKLIST_REGART_ART_INTEGRATION.md" "$ART_CHECKLIST"
grep -q "my_langgraph_agent" "$ART_CHECKLIST"

# Reject inconsistent checklist state: parent [x] with unchecked child [ ].
python3 - "$ART_CHECKLIST" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()
parent_done = False
parent_line = ""
for ln in lines:
    if re.match(r"^- \[(x| )\] \*\*\d+\. Сделать:", ln):
        parent_done = ln.startswith("- [x]")
        parent_line = ln
        continue
    if parent_done and re.match(r"^  - \[ \]", ln):
        raise SystemExit(f"inconsistent checklist state: parent done but child open\nparent: {parent_line}\nchild: {ln}")
PY

# Required evidence names in wrapper docs/checklist must be explicit.
for name in \
  test_drop_oldest_when_full_logs_lossy \
  test_art_ingest_https_only_rejects_http \
  test_art_ingest_tls_smoke_self_signed \
  test_upstream_error_format_contains_required_fields \
  test_retry_count_present_and_non_negative \
  test_audit_immutability_append_only
  do
  grep -q "$name" "$ART_CHECKLIST"
done
grep -q "test_ui_proxy_service_actions" "$ART_CHECKLIST"

if [[ "$STRICT_EXTERNAL" -eq 1 ]]; then
  # Stage06 requirement: service management only through Art Actions API.
  grep -q "ART_ACTIONS_URL" "$UI_PROXY"
  grep -q "/api/v1/actions/execute" "$UI_PROXY"
  grep -q "def _call_art_action" "$UI_PROXY"
  grep -q "observability_gap.actions.failure" "$UI_PROXY"

  # Direct service control via systemctl/tmux/shell helpers is forbidden.
  if rg -n "systemctl|tmux|os\.system" "$UI_PROXY"; then
    echo "stage06: forbidden direct service control found in ui_proxy.py"
    exit 1
  fi

  # Critical service helper functions must call Art Actions API path.
  python3 - "$UI_PROXY" <<'PY'
from pathlib import Path
import ast
import sys

path = Path(sys.argv[1])
module = ast.parse(path.read_text(encoding='utf-8'))

fn = {n.name: n for n in module.body if isinstance(n, ast.FunctionDef)}
required = ["_call_art_action", "_systemd_user_action", "_systemd_user_service_status"]
missing = [name for name in required if name not in fn]
if missing:
    raise SystemExit(f"missing required functions: {missing}")

def calls(func, target):
    for node in ast.walk(func):
        if isinstance(node, ast.Call):
            callee = node.func
            if isinstance(callee, ast.Name) and callee.id == target:
                return True
            if isinstance(callee, ast.Attribute) and callee.attr == target:
                return True
    return False

if not calls(fn["_systemd_user_action"], "_call_art_action"):
    raise SystemExit("_systemd_user_action does not call _call_art_action")
if not calls(fn["_systemd_user_service_status"], "_call_art_action"):
    raise SystemExit("_systemd_user_service_status does not call _call_art_action")
PY

  # Required integration evidence names must exist in source-of-truth tests.
  for name in \
    test_drop_oldest_when_full_logs_lossy \
    test_art_ingest_https_only_rejects_http \
    test_art_ingest_tls_smoke_self_signed \
    test_upstream_error_format_contains_required_fields \
    test_retry_count_present_and_non_negative \
    test_audit_immutability_append_only
    do
    grep -q "$name" "$ITESTS"
  done

  python3 - "$EXT_CHECKLIST" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()
parent_done = False
parent_line = ""
for ln in lines:
    if re.match(r"^- \[(x| )\] \*\*\d+\. Сделать:", ln):
        parent_done = ln.startswith("- [x]")
        parent_line = ln
        continue
    if parent_done and re.match(r"^  - \[ \]", ln):
        raise SystemExit(f"inconsistent checklist state in source-of-truth\nparent: {parent_line}\nchild: {ln}")
PY
else
  echo "stage06: strict external code checks skipped (no local source-of-truth checkout)"
fi

# Core requirement phrases must be present.
PHRASE_TARGET="$ART_CHECKLIST"
if [[ "$STRICT_EXTERNAL" -eq 1 ]]; then
  PHRASE_TARGET="$EXT_CHECKLIST"
fi
for phrase in \
  "never_drop_unacked" \
  "drop_oldest_when_full" \
  "Actions-only" \
  "HTTPS-only" \
  "upstream_error" \
  "retry_count" \
  "audit immutability"
  do
  grep -qi "$phrase" "$PHRASE_TARGET"
done

bash "$ROOT/scripts/ci/check_regart_adversarial_harness.sh"

echo "stage06 wrapper gate: OK"
