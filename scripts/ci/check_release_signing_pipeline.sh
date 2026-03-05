#!/usr/bin/env bash
set -euo pipefail
WF=.github/workflows/release_stage04.yml

test -s "$WF"
grep -q "cosign sign-blob" "$WF"
grep -q "cosign verify-blob" "$WF"
grep -q "id-token: write" "$WF"
grep -q "method=cosign-keyless-oidc" "$WF"

echo "release signing pipeline check: OK"
