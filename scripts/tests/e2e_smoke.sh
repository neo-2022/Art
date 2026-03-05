#!/usr/bin/env bash
set -euo pipefail

# Stage22 e2e smoke must execute runtime behavior checks (not docs grep only).
cargo test -p art-core stream_returns_sse_for_valid_cursor
cargo test -p art-core ingest_ack_upto_seq_is_monotonic_after_error_recovery

echo "e2e-smoke: OK"
