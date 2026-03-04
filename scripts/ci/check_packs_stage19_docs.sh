#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/packs/spec.md \
  docs/packs/versioning.md \
  docs/packs/signing.md \
  docs/runbooks/pack_install_failed.md; do
  test -s "$f"
done

grep -q "автообновления запрещены" docs/packs/versioning.md
grep -q "ручная установка" docs/packs/versioning.md
grep -q "manifest.yaml" docs/packs/spec.md
grep -q "dependencies" docs/packs/spec.md
grep -q "cosign" docs/packs/signing.md
grep -q "verify" docs/packs/signing.md
grep -q "mitigations" docs/runbooks/pack_install_failed.md
grep -q "verification" docs/runbooks/pack_install_failed.md

echo "stage19 docs gate: OK"
