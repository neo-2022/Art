#!/usr/bin/env bash
set -euo pipefail

bash scripts/tests/stage33_action_flow_anti_breakage_e2e.sh

test -s docs/governance/evidence/stage33_step7_action_flow_anti_breakage.png

echo "stage33 action ux anti-breakage gate: OK"
