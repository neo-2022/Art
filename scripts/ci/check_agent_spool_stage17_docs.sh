#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/agent/spool.md \
  docs/agent/spool_policies.md \
  docs/agent/recovery.md \
  docs/agent/spool_chaos.md \
  docs/runbooks/spool_full.md \
  docs/runbooks/spool_corrupted.md \
  docs/runbooks/spool_disk_full.md \
  docs/runbooks/lossy_mode_active.md; do
  test -s "$f"
done

grep -q "never_drop_unacked" docs/agent/spool_policies.md
grep -q "drop_oldest_when_full" docs/agent/spool_policies.md
grep -q "spool_corrupted" docs/agent/recovery.md
grep -q "kill -9" docs/agent/spool_chaos.md
grep -q "disk full" docs/agent/spool_chaos.md
grep -q "agent_spool_chaos_runtime.sh" docs/agent/spool_chaos.md

for f in \
  docs/runbooks/spool_full.md \
  docs/runbooks/spool_corrupted.md \
  docs/runbooks/spool_disk_full.md \
  docs/runbooks/lossy_mode_active.md; do
  grep -q "mitigations" "$f"
  grep -q "verification" "$f"
done

echo "stage17 docs gate: OK"
