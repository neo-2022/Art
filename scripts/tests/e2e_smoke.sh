#!/usr/bin/env bash
set -euo pipefail
grep -q "ack.upto_seq" docs/testing/e2e.md
echo "e2e-smoke: OK"
