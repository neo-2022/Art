#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml
# Ubuntu-only quick integration smoke for Art <-> REGART contract path.

bash scripts/tests/pack_regart_runtime_api.sh

echo "ubuntu REGART integration smoke: OK"
