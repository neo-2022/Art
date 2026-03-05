#!/usr/bin/env bash
set -euo pipefail

has_pattern() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -qE "$pattern" "$file"
  fi
}

test -s README.md || { echo "README.md is missing or empty"; exit 1; }
test -s docs/development/getting_started.md || { echo "docs/development/getting_started.md is missing or empty"; exit 1; }
test -s docs/development/dev_env.md || { echo "docs/development/dev_env.md is missing or empty"; exit 1; }

has_pattern "Contracts" README.md || { echo "README.md: missing Contracts section"; exit 1; }
has_pattern "Stage 08" README.md || { echo "README.md: missing Stage 08 declaration"; exit 1; }
has_pattern "OpenAPI" README.md || { echo "README.md: missing OpenAPI mention"; exit 1; }
has_pattern "JSON Schema" README.md || { echo "README.md: missing JSON Schema mention"; exit 1; }

has_pattern "cargo" docs/development/getting_started.md || { echo "getting_started.md: missing cargo commands"; exit 1; }
has_pattern "node|npm|pnpm" docs/development/getting_started.md || { echo "getting_started.md: missing Node/npm/pnpm commands"; exit 1; }
has_pattern "license-checker" docs/development/getting_started.md || { echo "getting_started.md: missing license-checker command"; exit 1; }

has_pattern "Rust" docs/development/dev_env.md || { echo "dev_env.md: missing Rust section"; exit 1; }
has_pattern "Node" docs/development/dev_env.md || { echo "dev_env.md: missing Node section"; exit 1; }

echo "stage07 gate: OK"
