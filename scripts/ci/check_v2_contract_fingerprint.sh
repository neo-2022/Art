#!/usr/bin/env bash
set -euo pipefail

EXPECTED_FILE="docs/contracts/v2/contract_fingerprint.sha256"
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

contracts=(
  "docs/contracts/v2/openapi.yaml"
)

while IFS= read -r file; do
  contracts+=("$file")
done < <(find docs/contracts/v2/schemas -maxdepth 1 -type f -name '*.json' | sort)

for file in "${contracts[@]}"; do
  test -s "$file"
  sha256sum "$file" >> "$TMP_FILE"
done

if [[ ! -f "$EXPECTED_FILE" ]]; then
  echo "missing expected fingerprint file: $EXPECTED_FILE"
  echo "create it with:"
  echo "  cp $TMP_FILE $EXPECTED_FILE"
  exit 1
fi

if ! diff -u "$EXPECTED_FILE" "$TMP_FILE"; then
  echo "v2 contract fingerprint mismatch"
  echo "if change is intentional, update $EXPECTED_FILE with current values"
  exit 1
fi

echo "stage29 contract fingerprint: OK"
