#!/usr/bin/env bash
set -euo pipefail

for f in \
  docs/packs/regart/README.md \
  docs/packs/regart/receivers_examples.md \
  docs/packs/regart/troubleshooting.md \
  docs/runbooks/pack_incompatible.md \
  docs/source/connected_system_visibility_v0_2.md \
  docs/source/regart_adversarial_integration_harness_v0_2.md; do
  test -f "$f"
done

test -x scripts/tests/pack_regart_runtime_api.sh

grep -q "fixtures" docs/packs/regart/README.md
grep -q "correlation" docs/packs/regart/README.md
grep -q "pack_regart_runtime_api.sh" docs/packs/regart/README.md
grep -q "Browser Level0" docs/packs/regart/README.md
grep -q "LangGraph" docs/packs/regart/README.md
grep -qi "harness" docs/packs/regart/README.md
grep -q "Connected System View" docs/packs/regart/README.md
grep -q "regart-browser-level0" docs/packs/regart/README.md
grep -q "connection_status" docs/packs/regart/README.md
grep -q "journald" docs/packs/regart/receivers_examples.md
grep -q "systemd_unit" docs/packs/regart/receivers_examples.md
grep -q "file_tail" docs/packs/regart/receivers_examples.md
grep -q "stdout_stderr" docs/packs/regart/receivers_examples.md
grep -q "proc_probe" docs/packs/regart/receivers_examples.md
grep -q "net_probe" docs/packs/regart/receivers_examples.md
grep -q "ui.graph.empty" docs/packs/regart/troubleshooting.md
grep -q "upstream_error" docs/packs/regart/troubleshooting.md
grep -q "bridge_backlog_recovered" docs/packs/regart/troubleshooting.md
grep -q "mitigations" docs/runbooks/pack_incompatible.md
grep -q "verification" docs/runbooks/pack_incompatible.md
grep -q "service_inventory" packs/regart/manifest.yaml
grep -q "connected_system_projection" packs/regart/manifest.yaml

bash scripts/ci/check_regart_adversarial_harness.sh
bash scripts/ci/check_connected_system_visibility.sh

echo "stage20 docs gate: OK"
