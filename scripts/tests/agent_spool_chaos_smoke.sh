#!/usr/bin/env bash
set -euo pipefail

# Stage17 chaos smoke must execute real recovery and full-capacity behavior tests.
cargo test -p art-agent spool_corruption_recovery_creates_new_spool_and_gap
cargo test -p art-agent spool_disk_full_generates_gap
cargo test -p art-agent never_drop_unacked_rejects_and_pauses_receivers

echo "agent-spool-chaos-smoke: OK"
