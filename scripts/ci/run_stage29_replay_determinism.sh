#!/usr/bin/env bash
set -euo pipefail

cargo test -p art-core dna_reference_implementation_parity_corpus
cargo test -p art-core dna_clusters_are_monotonic_for_append_only_sequence
cargo test -p art-core dna_property_determinism_proptest

echo "stage29 replay determinism suite: OK"
