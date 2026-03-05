#!/usr/bin/env bash
set -euo pipefail

test -s README.md || { echo "README.md is missing or empty"; exit 1; }
test -s docs/development/getting_started.md || { echo "docs/development/getting_started.md is missing or empty"; exit 1; }
test -s docs/development/dev_env.md || { echo "docs/development/dev_env.md is missing or empty"; exit 1; }

rg -q "Contracts" README.md || { echo "README.md: missing Contracts section"; exit 1; }
rg -q "Stage 08" README.md || { echo "README.md: missing Stage 08 declaration"; exit 1; }
rg -q "OpenAPI" README.md || { echo "README.md: missing OpenAPI mention"; exit 1; }
rg -q "JSON Schema" README.md || { echo "README.md: missing JSON Schema mention"; exit 1; }

rg -q "cargo" docs/development/getting_started.md || { echo "getting_started.md: missing cargo commands"; exit 1; }
rg -q "node|npm|pnpm" docs/development/getting_started.md || { echo "getting_started.md: missing Node/npm/pnpm commands"; exit 1; }
rg -q "license-checker" docs/development/getting_started.md || { echo "getting_started.md: missing license-checker command"; exit 1; }

rg -q "Rust" docs/development/dev_env.md || { echo "dev_env.md: missing Rust section"; exit 1; }
rg -q "Node" docs/development/dev_env.md || { echo "dev_env.md: missing Node section"; exit 1; }

echo "stage07 gate: OK"
