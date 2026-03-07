#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/agent/receivers.md \
  docs/agent/receivers_config.md \
  docs/agent/receivers_state.md \
  docs/agent/receivers_chaos.md \
  docs/source/connected_system_visibility_v0_2.md \
  docs/runbooks/receiver_paused_spool_full.md \
  docs/runbooks/receiver_permission_denied.md \
  docs/runbooks/receiver_read_failed.md \
  docs/runbooks/receiver_process_spawn_failed.md \
  docs/runbooks/receiver_process_exited.md; do
  test -s "$f"
done

grep -q "receiver_kind" docs/agent/receivers.md
grep -q "source_id" docs/agent/receivers.md
grep -q "source_seq" docs/agent/receivers.md
grep -q "file_tail" docs/agent/receivers_config.md
grep -q "journald" docs/agent/receivers_config.md
grep -q "stdout_stderr" docs/agent/receivers_config.md
grep -q "offset" docs/agent/receivers_state.md
grep -q "cursor" docs/agent/receivers_state.md
grep -q "agent_receivers_chaos_runtime.sh" docs/agent/receivers_chaos.md
grep -q "receiver_process_spawn_failed" docs/agent/receivers_chaos.md
grep -q "produced_data_kinds" docs/agent/receiver_source_coverage.md
grep -q "connected_system_projection" docs/agent/receiver_source_coverage.md
grep -q "Connected System View" docs/source/connected_system_visibility_v0_2.md
grep -q "declared_data_kinds" docs/source/connected_system_visibility_v0_2.md
grep -q "observed_data_kinds" docs/source/connected_system_visibility_v0_2.md

for f in \
  docs/runbooks/receiver_paused_spool_full.md \
  docs/runbooks/receiver_permission_denied.md \
  docs/runbooks/receiver_read_failed.md \
  docs/runbooks/receiver_process_spawn_failed.md \
  docs/runbooks/receiver_process_exited.md; do
  grep -q "mitigations" "$f"
  grep -q "verification" "$f"
done

echo "stage18 docs gate: OK"
