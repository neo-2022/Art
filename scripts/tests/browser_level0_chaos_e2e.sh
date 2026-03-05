#!/usr/bin/env bash
set -euo pipefail

cd browser
node --test test/multitab.e2e.test.js test/outbox.compression.test.js test/level0.chaos.e2e.test.js

echo "browser level0 chaos/e2e: OK"
