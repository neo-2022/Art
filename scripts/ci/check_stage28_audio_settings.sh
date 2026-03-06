#!/usr/bin/env bash
set -euo pipefail

test -s "docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md"
test -s "docs/source/console_settings_architecture_v0_2.md"
test -s "scripts/tests/console_audio_settings_e2e.sh"

grep -q "stage28-audio-settings-e2e" docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
grep -q "Settings Profile Manager" docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
grep -q "Audio & Haptics" docs/source/console_settings_architecture_v0_2.md
grep -q "Global" docs/source/console_settings_architecture_v0_2.md
grep -q "Organization" docs/source/console_settings_architecture_v0_2.md
grep -q "Project" docs/source/console_settings_architecture_v0_2.md
grep -q "Environment" docs/source/console_settings_architecture_v0_2.md
grep -q "User" docs/source/console_settings_architecture_v0_2.md
grep -q "Audio Effects Ownership Law" docs/source/FOUNDATION_CONSTITUTION_V0_2.md
grep -q "Settings Profile Manager обязателен" docs/source/FOUNDATION_CONSTITUTION_V0_2.md

if [[ -x "${HOME}/.codex/skills/playwright/scripts/playwright_cli.sh" ]]; then
  bash scripts/tests/console_audio_settings_e2e.sh
else
  echo "playwright-cli wrapper not found; fallback to console-web tests only"
  corepack pnpm --filter ./apps/console-web run test
fi

echo "stage28 audio/settings gate: OK"
