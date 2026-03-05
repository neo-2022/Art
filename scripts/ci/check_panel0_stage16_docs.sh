#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/ui/panel0.md"
  "docs/ui/panel0_offline.md"
  "docs/ui/panel0_sw_cache.md"
  "docs/runbooks/console_boot_failed.md"
  "docs/governance/observability_gap_registry.md"
  "docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md"
  "docs/ops/panel0_linux_prod_readiness.md"
)

for f in "${required_files[@]}"; do
  test -f "$f"
done

grep -q "Авто-fallback" docs/ui/panel0.md
grep -q "Ctrl+Shift+P" docs/ui/panel0.md
grep -q "PANEL0_BUILD_ID" docs/ui/panel0.md
grep -q "ART_CONSOLE_BASE_PATH" docs/ui/panel0.md
grep -q "Core DOWN + Console DOWN" docs/ui/panel0.md
grep -q "observability_gap.console_boot_failed" docs/ui/panel0.md
grep -q "offline" docs/ui/panel0_offline.md
grep -q "Reload" docs/ui/panel0_offline.md
grep -q "panel0-cache-" docs/ui/panel0_sw_cache.md
grep -q "skipWaiting" docs/ui/panel0_sw_cache.md
grep -q "x-art-offline" docs/ui/panel0_sw_cache.md
grep -q "secure context" docs/ui/panel0_sw_cache.md

grep -q "^## Symptoms" docs/runbooks/console_boot_failed.md
grep -q "^## Diagnosis" docs/runbooks/console_boot_failed.md
grep -q "^## Resolution" docs/runbooks/console_boot_failed.md
grep -q "^## Rollback" docs/runbooks/console_boot_failed.md

grep -q "scripts/tests/panel0_linux_prod_readiness.sh" docs/ops/panel0_linux_prod_readiness.md
grep -q "Console UP" docs/ops/panel0_linux_prod_readiness.md
grep -q "Core DOWN + Console DOWN" docs/ops/panel0_linux_prod_readiness.md

registry_row="$(grep '^\| observability_gap.console_boot_failed \|' docs/governance/observability_gap_registry.md || true)"
if [[ -z "${registry_row}" ]]; then
  echo "missing observability_gap.console_boot_failed row in registry"
  exit 1
fi
for token in reason_type url http_status error_text timeout_ms build_id effective_profile_id trace_id; do
  if [[ "${registry_row}" != *"${token}"* ]]; then
    echo "registry row missing token: ${token}"
    exit 1
  fi
done
for token in browser/panel0 log_only docs/runbooks/console_boot_failed.md; do
  if [[ "${registry_row}" != *"${token}"* ]]; then
    echo "registry row missing token: ${token}"
    exit 1
  fi
done

grep -q "e2e: auto-fallback при Console DOWN (5s timeout)" docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
grep -q "e2e: observability_gap.console_boot_failed появляется в snapshot/stream" docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
grep -q "e2e: hotkey Ctrl+Shift+P открывает Panel0" docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
grep -q "e2e: Core DOWN + Console DOWN -> core-down placeholder" docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
