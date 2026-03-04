#!/usr/bin/env bash
set -euo pipefail
for f in docs/core/ingest_protocol.md docs/api/errors.md docs/metrics/ingest.md docs/ops/ingest_chaos.md docs/runbooks/ingest_overloaded.md docs/runbooks/ingest_payload_too_large.md docs/runbooks/ingest_unavailable.md; do
  test -s "$f"
done
grep -q "ack.upto_seq" docs/core/ingest_protocol.md
grep -q "seq" docs/core/ingest_protocol.md
grep -q "invalid_details" docs/api/errors.md
grep -q "retry_after_ms" docs/api/errors.md
grep -q "ingest_dropped_total" docs/metrics/ingest.md
echo "stage12 docs gate: OK"
