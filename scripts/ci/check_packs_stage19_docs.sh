#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/packs/spec.md \
  docs/packs/versioning.md \
  docs/packs/signing.md \
  docs/packs/source_coverage.md \
  docs/source/connected_system_visibility_v0_2.md \
  docs/runbooks/pack_install_failed.md; do
  test -s "$f"
done

test -x scripts/tests/pack_install_runtime.sh

grep -q "автообновления запрещены" docs/packs/versioning.md
grep -q "ручная установка" docs/packs/versioning.md
grep -q "manifest.yaml" docs/packs/spec.md
grep -q "dependencies" docs/packs/spec.md
grep -q "signal_coverage_claims" docs/packs/spec.md
grep -q "connected_system_projection" docs/packs/spec.md
grep -q "service_inventory" docs/packs/source_coverage.md
grep -q "telemetry_endpoints" docs/packs/source_coverage.md
grep -q "regulatory_tags" docs/packs/source_coverage.md
grep -q "Connected System View" docs/source/connected_system_visibility_v0_2.md
grep -q "cosign" docs/packs/signing.md
grep -q "verify" docs/packs/signing.md
grep -q "mitigations" docs/runbooks/pack_install_failed.md
grep -q "verification" docs/runbooks/pack_install_failed.md

echo "stage19 docs gate: OK"
