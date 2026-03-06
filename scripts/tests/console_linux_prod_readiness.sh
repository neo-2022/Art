#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

echo "[console-linux] install workspace"
corepack pnpm install --frozen-lockfile >/dev/null

echo "[console-linux] build console foundation"
corepack pnpm run console:build >/dev/null

INDEX_FILE="apps/console-web/dist/index.html"
test -s "$INDEX_FILE"

grep -q 'lang="en"' "$INDEX_FILE"
grep -q 'data-locale="ru"' "$INDEX_FILE"
grep -q '/console/command-center' "$INDEX_FILE"
grep -q '/console/event-river' "$INDEX_FILE"
grep -q '/console/incident-room' "$INDEX_FILE"
grep -q '/console/scenario-view' "$INDEX_FILE"
grep -q '/console/time-field' "$INDEX_FILE"
grep -q '/console/audit-explorer' "$INDEX_FILE"
grep -q '/console/action-studio' "$INDEX_FILE"
grep -q '/console/evidence/sample-evidence' "$INDEX_FILE"

echo "[console-linux] foundation readiness OK"
