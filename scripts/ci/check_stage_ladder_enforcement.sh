#!/usr/bin/env bash
set -euo pipefail

MASTER="docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md"
INCIDENT_STATE="docs/ops/runtime_incident_status.json"

find_open_tasks() {
  local file="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -n '^- \[ \]' "$file"
  else
    grep -En '^- \[ \]' "$file"
  fi
}

find_closed_dependency_claims() {
  local file="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -No 'CHECKLIST[[:space:]]+([0-9]{2})[[:space:]]*\(закрыт\)' "$file"
  else
    grep -Eo 'CHECKLIST[[:space:]]+([0-9]{2})[[:space:]]*\(закрыт\)' "$file"
  fi
}

bash scripts/ci/check_master_checklist_binding.sh
bash scripts/ci/check_checklist_status_integrity.sh
bash scripts/ci/check_docs_master_traceability.sh
bash scripts/ci/check_evidence_ledger.sh
bash scripts/ci/check_protective_safeguards_catalog.sh

test -s "$MASTER"

# stage -> checklist file
get_checklist_file() {
  case "$1" in
    28) echo "docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md" ;;
    29) echo "docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md" ;;
    30) echo "docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md" ;;
    31) echo "docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md" ;;
    32) echo "docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md" ;;
    33) echo "docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md" ;;
    34) echo "docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md" ;;
    35) echo "docs/source/checklists/CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md" ;;
    36) echo "docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md" ;;
    37) echo "docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md" ;;
    38) echo "docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md" ;;
    39) echo "docs/source/checklists/CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md" ;;
    40) echo "docs/source/checklists/CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md" ;;
    41) echo "docs/source/checklists/CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md" ;;
    42) echo "docs/source/checklists/CHECKLIST_42_EVIDENCE_INTELLIGENCE_AND_DRIFT.md" ;;
    43) echo "docs/source/checklists/CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md" ;;
    44) echo "docs/source/checklists/CHECKLIST_44_INCIDENT_CAPSULE_AND_TWIN.md" ;;
    45) echo "docs/source/checklists/CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md" ;;
    *)
      echo "unknown stage: $1" >&2
      exit 1
      ;;
  esac
}

declare -A status
for stage in $(seq 28 45); do
  row="$(grep -E "^\| \[[ x]\] ${stage} \|" "$MASTER" || true)"
  if [[ -z "$row" ]]; then
    echo "missing stage row ${stage} in MASTER"
    exit 1
  fi
  marker="$(sed -E 's/^\| \[([ x])\].*/\1/' <<<"$row")"
  status[$stage]="$marker"
done

# Ladder rule: after first unchecked stage, all following must be unchecked.
found_open=0
for stage in $(seq 28 45); do
  marker="${status[$stage]}"
  if [[ "$marker" == "x" ]]; then
    if [[ "$found_open" -eq 1 ]]; then
      echo "ladder violation: stage ${stage} is [x] while previous stage is [ ]"
      exit 1
    fi
  else
    found_open=1
  fi
done

# If stage is marked [x] in MASTER, corresponding checklist must have no open [ ] items.
for stage in $(seq 28 45); do
  marker="${status[$stage]}"
  if [[ "$marker" == "x" ]]; then
    checklist="$(get_checklist_file "$stage")"
    test -s "$checklist"
    if find_open_tasks "$checklist" >/dev/null; then
      echo "status integrity violation: stage ${stage} marked [x] but checklist has open tasks"
      find_open_tasks "$checklist" || true
      exit 1
    fi
  fi
done

# Dependency consistency: if checklist text says "CHECKLIST N (закрыт)",
# MASTER must mark stage N as closed.
for checklist in $(rg --files docs/source/checklists -g 'CHECKLIST_2[8-9]_*.md' -g 'CHECKLIST_3[0-9]_*.md' -g 'CHECKLIST_4[0-5]_*.md'); do
  while IFS= read -r dep_stage; do
    dep_marker="${status[$dep_stage]:-}"
    if [[ -z "$dep_marker" ]]; then
      echo "dependency consistency violation: unknown stage ${dep_stage} in ${checklist}"
      exit 1
    fi
    if [[ "$dep_marker" != "x" ]]; then
      echo "dependency consistency violation: ${checklist} declares CHECKLIST ${dep_stage} as '(закрыт)' but MASTER is [ ]"
      exit 1
    fi
  done < <(find_closed_dependency_claims "$checklist" \
    | sed -E 's/.*CHECKLIST[[:space:]]+([0-9]{2}).*/\1/')
done

# Determinism safety: do not allow stage closure flow while open deterministic incidents exist.
if [[ -s "$INCIDENT_STATE" ]]; then
  python3 - "$INCIDENT_STATE" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))
det = int(obj.get("open_determinism_incidents", 0))
canary = int(obj.get("open_canary_divergence_incidents", 0))
if det > 0 or canary > 0:
    raise SystemExit(
        f"ladder safety violation: open deterministic incidents present "
        f"(open_determinism_incidents={det}, open_canary_divergence_incidents={canary})"
    )
PY
fi

echo "stage ladder enforcement: OK"
