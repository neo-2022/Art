#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/ui/panel0.md"
  "docs/ui/panel0_offline.md"
  "docs/ui/panel0_sw_cache.md"
)

for f in "${required_files[@]}"; do
  test -f "$f"
done

grep -q "observability_gap." docs/ui/panel0.md
grep -q "offline" docs/ui/panel0_offline.md
grep -q "Reload" docs/ui/panel0_offline.md
grep -q "panel0-cache-" docs/ui/panel0_sw_cache.md
grep -q "skipWaiting" docs/ui/panel0_sw_cache.md
grep -q "x-art-offline" docs/ui/panel0_sw_cache.md
grep -q "secure context" docs/ui/panel0_sw_cache.md
