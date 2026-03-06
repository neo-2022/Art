#!/usr/bin/env bash
set -euo pipefail

DOC="docs/source/perf_load_coverage_v0_2.md"

grep -q "p95" "$DOC"
grep -q "p99" "$DOC"
grep -q "10k/сек" "$DOC"
grep -q "100k/сек" "$DOC"
grep -q "5%" "$DOC"

# Runtime smoke to ensure v2 data-path remains healthy before load suites.
cargo test -p art-core v2_ingest_snapshot_stream_integration -- --nocapture

echo "stage34 perf/load smoke: OK"
