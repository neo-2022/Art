#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

DOC="docs/source/regart_adversarial_integration_harness_v0_2.md"
YAML_FILE="formats/regart_adversarial_harness_v0_2.yaml"

test -s "$DOC"
test -s "$YAML_FILE"

python3 - <<'PY'
import pathlib
import sys
import yaml

doc = pathlib.Path("docs/source/regart_adversarial_integration_harness_v0_2.md").read_text(encoding="utf-8")
cfg = yaml.safe_load(pathlib.Path("formats/regart_adversarial_harness_v0_2.yaml").read_text(encoding="utf-8"))

required_doc_markers = [
    "Три канала данных",
    "`art-regart-smoke`",
    "`art-regart-hostile-bridge`",
    "`art-regart-replay`",
    "`art-regart-long-chain`",
    "`art-regart-actions-audit`",
    "pinned git commit",
    "Browser Level0",
    "UI Proxy",
    "LangGraph runtime",
]

errors = []
for marker in required_doc_markers:
    if marker not in doc:
        errors.append(f"missing doc marker: {marker}")

expected_order = ["art_core", "art_agent", "regart_backend", "regart_ui_proxy", "regart_browser_level0"]
if cfg.get("startup_order") != expected_order:
    errors.append(f"unexpected startup_order: {cfg.get('startup_order')}")

suite_ids = [suite["id"] for suite in cfg.get("suites", [])]
for expected in [
    "art-regart-smoke",
    "art-regart-hostile-bridge",
    "art-regart-replay",
    "art-regart-long-chain",
    "art-regart-actions-audit",
]:
    if expected not in suite_ids:
        errors.append(f"missing suite id: {expected}")

allowed = set(cfg.get("source_policy", {}).get("allowed_modes", []))
forbidden = set(cfg.get("source_policy", {}).get("forbidden_modes", []))
if "pinned_git_commit" not in allowed:
    errors.append("allowed_modes missing pinned_git_commit")
if "floating_main" not in forbidden:
    errors.append("forbidden_modes missing floating_main")

required_docs = set(cfg.get("required_documents", []))
for expected_doc in [
    "docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md",
    "docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md",
    "docs/source/checklists/CHECKLIST_20_PACK_REGART.md",
    "docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md",
    "docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md",
]:
    if expected_doc not in required_docs:
        errors.append(f"required_documents missing {expected_doc}")

if errors:
    print("regart adversarial harness gate: FAIL")
    for err in errors:
        print(f" - {err}")
    sys.exit(1)

print("regart adversarial harness gate: OK")
PY
