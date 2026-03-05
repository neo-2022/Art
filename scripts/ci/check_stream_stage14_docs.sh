#!/usr/bin/env bash
set -euo pipefail

test -s docs/api/stream.md
test -s docs/api/snapshot.md
test -s docs/metrics/stream.md
test -s docs/runbooks/stream_unavailable.md
test -s docs/runbooks/stream_lag.md
test -s docs/perf/stream_10k_events.md
test -s docs/perf/stream_1000_subscribers.md

grep -q "Last-Event-ID" docs/api/stream.md
grep -q "X-Stream-Cursor" docs/api/stream.md
grep -q "86400000" docs/api/stream.md
grep -q "stream_lag_ms" docs/metrics/stream.md
grep -q "mitigations" docs/runbooks/stream_unavailable.md
grep -q "verification" docs/runbooks/stream_unavailable.md
grep -q "mitigations" docs/runbooks/stream_lag.md
grep -q "verification" docs/runbooks/stream_lag.md
