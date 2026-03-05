#!/usr/bin/env bash
set -euo pipefail

# Stage21: run real core integration tests that emit self-observability gaps.
cargo test -p art-core pipeline_source_stale_emits_gap_after_10_minutes
cargo test -p art-core metrics_unavailable_emits_gap_event

# Validate incident/alert/runbook registry consistency.
python3 -m unittest scripts/tests/test_self_observability.py

echo "self-observability-runtime-smoke: OK"
