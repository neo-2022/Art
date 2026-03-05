#!/usr/bin/env bash
set -euo pipefail

# Stage22 chaos smoke: run runtime resilience tests for loss/recovery paths.
cargo test -p art-agent spool_disk_full_generates_gap
cargo test -p art-agent spool_corruption_recovery_creates_new_spool_and_gap
cargo test -p art-core ingest_storage_error_increments_dropped_and_pushes_unavailable_gap
python3 -m unittest scripts/tests/test_stage22_e2e.py -k test_power_loss_recovery_contract

echo "e2e-chaos: OK"
