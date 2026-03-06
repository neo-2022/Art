#!/usr/bin/env bash
set -euo pipefail

run_and_assert_nonzero() {
  local test_filter="$1"
  local output
  output="$(cargo test -p art-core "$test_filter" -- --nocapture 2>&1)"
  echo "$output"

  if grep -q "running 0 tests" <<<"$output"; then
    echo "stage29 dna gate failure: no tests executed for filter '$test_filter'" >&2
    exit 1
  fi
}

run_and_assert_nonzero dna_canonicalization_determinism_corpus_tests
run_and_assert_nonzero dna_schema_version_migration_compatibility_tests
run_and_assert_nonzero dna_property_determinism_proptest
run_and_assert_nonzero dna_reference_implementation_parity_corpus
run_and_assert_nonzero dna_mutation_resilience_sentinel_test
run_and_assert_nonzero dna_clusters_are_monotonic_for_append_only_sequence
run_and_assert_nonzero v2_ingest_snapshot_stream_integration
run_and_assert_nonzero v2_dna_clusters_and_similar_lookup
run_and_assert_nonzero v2_invalid_payload_returns_deterministic_error_codes

echo "stage29 dna tests: OK"
