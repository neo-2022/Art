#!/usr/bin/env bash
set -euo pipefail

files=(
  docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
  docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md
  docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
  docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md
  docs/source/checklists/CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
  docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
  docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md
  docs/source/checklists/CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md
  docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md
  docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
  docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
)

required_sections=(
  "## Цель"
  "## Границы"
  "## Зависимости"
  "## Шаги (строго линейно)"
  "## Документация (RU)"
  "## Тестирование"
  "## CI gate"
  "## DoD"
  "## Метаданные"
)

for file in "${files[@]}"; do
  test -s "$file"
  for section in "${required_sections[@]}"; do
    grep -q "^${section}$" "$file"
  done
  grep -q "Проверка (pass/fail)" "$file"
  grep -q "Артефакт результата" "$file"
  grep -q "observability_gap\." "$file"
  grep -q "Ограничение перехода" "$file"

  if rg -n "опционально|если нужно|где применимо|по возможности|или/либо|частично|допускается" "$file" >/dev/null; then
    echo "forbidden ambiguity phrase found in ${file}"
    rg -n "опционально|если нужно|где применимо|по возможности|или/либо|частично|допускается" "$file" || true
    exit 1
  fi
done

echo "v0.2 checklists quality: OK"
