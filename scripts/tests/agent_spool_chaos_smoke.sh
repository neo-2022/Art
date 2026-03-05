#!/usr/bin/env bash
set -euo pipefail

# Stage17 chaos smoke: runtime сценарии + targeted cargo checks.
bash scripts/tests/agent_spool_chaos_runtime.sh
cargo test -p art-agent spool_corruption_recovery_creates_new_spool_and_gap
cargo test -p art-agent spool_disk_full_generates_gap

echo "agent-spool-chaos-smoke: OK"
