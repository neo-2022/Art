#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/packs/regart/README.md \
  docs/packs/regart/receivers_examples.md \
  docs/packs/regart/troubleshooting.md \
  docs/runbooks/pack_incompatible.md; do
  test -f "$f"
done

test -x scripts/tests/pack_regart_runtime_api.sh

grep -q "fixtures" docs/packs/regart/README.md
grep -q "correlation" docs/packs/regart/README.md
grep -q "pack_regart_runtime_api.sh" docs/packs/regart/README.md
grep -q "journald" docs/packs/regart/receivers_examples.md
grep -q "file_tail" docs/packs/regart/receivers_examples.md
grep -q "stdout_stderr" docs/packs/regart/receivers_examples.md
grep -q "net_probe" docs/packs/regart/receivers_examples.md
grep -q "ui.graph.empty" docs/packs/regart/troubleshooting.md
grep -q "upstream_error" docs/packs/regart/troubleshooting.md
grep -q "mitigations" docs/runbooks/pack_incompatible.md
grep -q "verification" docs/runbooks/pack_incompatible.md
