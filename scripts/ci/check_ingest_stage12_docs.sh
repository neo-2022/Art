#!/usr/bin/env bash
set -euo pipefail
for f in docs/core/ingest_protocol.md docs/api/errors.md docs/metrics/ingest.md docs/ops/ingest_chaos.md docs/runbooks/ingest_overloaded.md docs/runbooks/ingest_payload_too_large.md docs/runbooks/ingest_unavailable.md docs/source/startup_config_safety_validator_v0_2.md docs/source/queue_integrity_protection_v0_2.md docs/source/guard_self_observability_v0_2.md docs/runbooks/unsafe_startup_config_refused.md docs/runbooks/queue_integrity_violation.md docs/runbooks/guard_self_test_failed.md; do
  test -s "$f"
done
grep -q "ack.upto_seq" docs/core/ingest_protocol.md
grep -q "seq" docs/core/ingest_protocol.md
grep -q "invalid_details" docs/api/errors.md
grep -q "retry_after_ms" docs/api/errors.md
grep -q "ingest_dropped_total" docs/metrics/ingest.md
grep -qi "unsafe startup config" docs/source/startup_config_safety_validator_v0_2.md
grep -qi "duplicate flood" docs/source/queue_integrity_protection_v0_2.md
grep -qi "replay loop" docs/source/queue_integrity_protection_v0_2.md
grep -qi "self-test" docs/source/guard_self_observability_v0_2.md
grep -qi "heartbeat" docs/source/guard_self_observability_v0_2.md
grep -q "mitigations" docs/runbooks/unsafe_startup_config_refused.md
grep -q "verification" docs/runbooks/unsafe_startup_config_refused.md
grep -q "mitigations" docs/runbooks/queue_integrity_violation.md
grep -q "verification" docs/runbooks/queue_integrity_violation.md
grep -q "mitigations" docs/runbooks/guard_self_test_failed.md
grep -q "verification" docs/runbooks/guard_self_test_failed.md
echo "stage12 docs gate: OK"
