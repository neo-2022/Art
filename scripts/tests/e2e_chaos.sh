#!/usr/bin/env bash
set -euo pipefail
grep -q "50%" docs/testing/chaos.md
grep -q "10 минут" docs/testing/chaos.md
grep -q "kill -9" docs/testing/chaos.md
echo "e2e-chaos: OK"
