#!/usr/bin/env bash
set -euo pipefail
cargo test -p art-core stream_load_smoke_1000_events_50_subscribers
