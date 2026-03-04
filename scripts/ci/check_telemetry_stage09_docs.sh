#!/usr/bin/env bash
set -euo pipefail
for f in docs/telemetry/otel_mapping.md docs/telemetry/otlp_receiver.md docs/telemetry/limits.md docs/runbooks/otlp_rate_limited.md; do test -s "$f"; done
grep -q "payload.otel_attributes" docs/telemetry/otel_mapping.md
grep -q "base64" docs/telemetry/otel_mapping.md
grep -q "otel.<key>" docs/telemetry/otel_mapping.md
grep -q "max_events_per_sec=200" docs/telemetry/otlp_receiver.md
grep -q "burst=400" docs/telemetry/otlp_receiver.md
grep -q "max_batch_events=200" docs/telemetry/otlp_receiver.md
grep -q "max_size_bytes=524288" docs/telemetry/otlp_receiver.md
grep -q "max_events_per_sec" docs/telemetry/limits.md
grep -q "max_size_bytes" docs/telemetry/limits.md
grep -q "mitigations" docs/runbooks/otlp_rate_limited.md
grep -q "verification" docs/runbooks/otlp_rate_limited.md
echo "stage09 telemetry docs gate: OK"
