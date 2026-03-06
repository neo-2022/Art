#!/usr/bin/env bash
set -euo pipefail

bash scripts/tests/stage35_flow_perf_2d_with_artifacts.sh

test -s docs/governance/evidence/stage34_step14_flow_perf_report.md
grep -q "watchdog activated: true" docs/governance/evidence/stage34_step14_flow_perf_report.md
grep -q "status=PASS" docs/governance/evidence/stage34_step14_watchdog_activation.log

echo "stage35 flow perf 2d gate: OK"
