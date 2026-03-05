#!/usr/bin/env bash
set -euo pipefail
for f in docs/testing/e2e.md docs/testing/chaos.md docs/testing/soak.md docs/perf/report.md docs/runbooks/e2e_environment_failed.md .github/workflows/nightly_chaos.yml; do
  test -s "$f"
done
grep -q "50%" docs/testing/chaos.md
grep -q "10 минут" docs/testing/chaos.md
grep -q "200" docs/perf/report.md
grep -q "15 минут" docs/perf/report.md
grep -q "RAM" docs/perf/report.md
grep -q "CPU" docs/perf/report.md
grep -q "24 часа" docs/testing/soak.md
grep -q "50 eps" docs/testing/soak.md
grep -q "kill -9" docs/testing/e2e.md
grep -q "ack.upto_seq" docs/testing/e2e.md
grep -q "mitigations" docs/runbooks/e2e_environment_failed.md
grep -q "verification" docs/runbooks/e2e_environment_failed.md
grep -q "schedule" .github/workflows/nightly_chaos.yml
echo "stage22 docs gate: OK"
