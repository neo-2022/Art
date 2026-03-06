#!/usr/bin/env bash
set -euo pipefail

TARGET="apps/console-web/src/main.ts"
BACKUP="$(mktemp)"

cleanup() {
  if [[ -f "$BACKUP" ]]; then
    cp "$BACKUP" "$TARGET"
    rm -f "$BACKUP"
  fi
}
trap cleanup EXIT

cp "$TARGET" "$BACKUP"

printf "\nimport { I18nCatalog as __boundary_smoke_import } from '../../packages/i18n/src/index';\nvoid __boundary_smoke_import;\n" >> "$TARGET"

set +e
output="$(bash scripts/ci/check_workspace_boundaries.sh 2>&1)"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  echo "expected boundary check to fail for forbidden relative import"
  echo "$output"
  exit 1
fi

echo "$output" | grep -q "workspace boundary violation: console uses direct relative imports into packages"

echo "workspace boundary negative smoke: OK"
