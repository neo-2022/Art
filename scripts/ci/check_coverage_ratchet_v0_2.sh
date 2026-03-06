#!/usr/bin/env bash
set -euo pipefail

BASELINE="docs/source/coverage_ratchet_baseline_v0_2.json"

test -s "$BASELINE"

python3 - "$BASELINE" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
obj = json.loads(path.read_text(encoding="utf-8"))
required_modules = [
    "apps/console-web",
    "packages/ui-laws",
    "packages/i18n",
    "packages/evidence-linking",
    "packages/worker-runtime",
    "packages/local-stores",
]
modules = obj.get("modules", {})
for module in required_modules:
    if module not in modules:
        raise SystemExit(f"missing module baseline: {module}")
    metrics = modules[module]
    for key in ("lines", "branches", "functions"):
        value = metrics.get(key)
        if value != 100:
            raise SystemExit(f"baseline target must be 100 for {module}:{key}, got {value}")
print("coverage baseline policy: OK")
PY

for pkg in apps/console-web packages/ui-laws packages/i18n packages/evidence-linking packages/worker-runtime packages/local-stores; do
  test -d "$pkg/test"
  test "$(find "$pkg/test" -type f | wc -l | tr -d ' ')" -ge 1
done

echo "coverage ratchet gate policy: OK"
