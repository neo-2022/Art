#!/usr/bin/env bash
set -euo pipefail

cargo test -p art-core otlp_logs_maps_attrs_unknown_severity_and_reserved_keys
cargo test -p art-core otlp_logs_returns_413_and_pushes_otlp_rate_limit_gap_for_large_batch
cargo test -p art-core otlp_logs_returns_429_and_pushes_gap_when_token_bucket_exhausted

echo "otlp runtime integration: OK"
