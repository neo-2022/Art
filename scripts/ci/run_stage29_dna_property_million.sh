#!/usr/bin/env bash
set -euo pipefail

output="$(cargo test -p art-core dna_property_determinism_million_sequences_gate -- --ignored --nocapture 2>&1)"
echo "$output"

if grep -q "running 0 tests" <<<"$output"; then
  echo "stage29 property million gate failure: no ignored heavy test executed" >&2
  exit 1
fi

echo "stage29 dna property million gate: OK"
