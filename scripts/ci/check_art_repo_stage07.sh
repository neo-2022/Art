#!/usr/bin/env bash
set -euo pipefail
test -s README.md
test -s docs/development/getting_started.md
test -s docs/development/dev_env.md
grep -q "Contracts" README.md
grep -q "Stage 08" README.md
grep -Eq "OpenAPI|JSON Schema" README.md
grep -q "cargo" docs/development/getting_started.md
grep -Eq "node|npm|pnpm" docs/development/getting_started.md
grep -q "license-checker" docs/development/getting_started.md
grep -q "Rust" docs/development/dev_env.md
grep -q "Node" docs/development/dev_env.md
echo "stage07 gate: OK"
