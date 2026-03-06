#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

ALLOWLIST="docs/security/certified_dependency_allowlist.txt"

test -s "$ALLOWLIST"
grep -q '^\[profile\.general\]' Cargo.toml
grep -q '^\[profile\.certified\]' Cargo.toml

# 1) no dynamic loader patterns in codebase
if rg -n "\bdlopen\b|libloading" core agent browser packages apps --glob '!**/node_modules/**' >/tmp/certified_dynamic_scan.log 2>/dev/null; then
  echo "certified profile violation: dynamic loading patterns found"
  cat /tmp/certified_dynamic_scan.log
  exit 1
fi

# 2) allowlist enforcement for rust dependencies
python3 - <<'PY'
import json
import pathlib
import subprocess
import sys

allow = set()
for line in pathlib.Path('docs/security/certified_dependency_allowlist.txt').read_text(encoding='utf-8').splitlines():
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    allow.add(line)

meta = json.loads(subprocess.check_output(['cargo', 'metadata', '--locked', '--format-version=1'], text=True))
actual = {pkg['name'] for pkg in meta['packages']}
missing = sorted(actual - allow)
if missing:
    print('certified allowlist mismatch: missing dependencies in allowlist:')
    for item in missing:
        print(f'  - {item}')
    sys.exit(1)
PY

# 3) build certified profile for both binaries
cargo build -p art-core --profile certified --locked >/dev/null
cargo build -p art-agent --profile certified --locked >/dev/null

for bin in target/certified/art-core target/certified/art-agent; do
  test -x "$bin"
  # disallow direct dependency on libdl in certified profile output
  if ldd "$bin" 2>/dev/null | grep -q 'libdl'; then
    echo "certified profile violation: $bin links libdl"
    ldd "$bin"
    exit 1
  fi
  if strings "$bin" | grep -qE '\bdlopen\b'; then
    echo "certified profile violation: $bin contains dlopen symbol"
    exit 1
  fi
done

echo "certified profile gate: OK"
