#!/usr/bin/env bash
set -euo pipefail

# Stage22 e2e smoke must execute runtime behavior checks (not docs grep only).
cargo test -p art-core stream_returns_sse_for_valid_cursor
cargo test -p art-core ingest_ack_upto_seq_is_monotonic_after_error_recovery
python3 -m unittest scripts/tests/test_stage22_e2e.py -k test_gap_event_has_required_evidence
python3 -m unittest scripts/tests/test_stage22_e2e.py -k test_ack_is_monotonic_after_recovery

echo "e2e-smoke: OK"
