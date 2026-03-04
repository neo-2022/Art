#!/usr/bin/env bash
set -euo pipefail
for f in docs/browser/level0_api.md docs/browser/outbox_limits.md docs/browser/cors_gap.md docs/browser/compression.md docs/browser/dlq.md docs/runbooks/cors_blocked.md docs/runbooks/outbox_decompress_failed.md docs/runbooks/outbox_event_expired.md docs/runbooks/worker_unavailable.md docs/runbooks/outbox_full.md docs/runbooks/lossy_mode_active.md; do test -s "$f"; done
grep -q "1024" docs/browser/compression.md
grep -q "gzip" docs/browser/compression.md
grep -q "7 суток" docs/browser/dlq.md
grep -q "30 суток" docs/browser/dlq.md
grep -q "observability_gap.cors_blocked" docs/browser/cors_gap.md
grep -q "never_drop_unacked" docs/browser/outbox_limits.md
grep -q "drop_oldest_when_full" docs/browser/outbox_limits.md
for f in docs/runbooks/cors_blocked.md docs/runbooks/outbox_decompress_failed.md docs/runbooks/outbox_event_expired.md docs/runbooks/worker_unavailable.md docs/runbooks/outbox_full.md docs/runbooks/lossy_mode_active.md; do
  grep -q "mitigations" "$f"
  grep -q "verification" "$f"
done
echo "stage10 browser docs gate: OK"
