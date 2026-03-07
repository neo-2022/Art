#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

POLICY_DOC="docs/governance/authenticity_copyright_policy.md"
ALLOWLIST="formats/authenticity_assets_allowlist.yaml"

test -s "$POLICY_DOC"
test -s "$ALLOWLIST"

python3 - "$ALLOWLIST" <<'PY'
from pathlib import Path
import fnmatch
import subprocess
import sys
import yaml

allowlist_path = Path(sys.argv[1])
cfg = yaml.safe_load(allowlist_path.read_text(encoding="utf-8"))

tracked = subprocess.check_output(["git", "ls-files"], text=True).splitlines()
forbidden_exts = {e.lower() for e in cfg["rules"]["forbidden_extensions"]}
allowed = cfg["rules"]["allowed_entries"]
patterns = cfg["rules"]["forbidden_runtime_reference_patterns"]
roots = cfg["runtime_scan_roots"]

def is_allowed(path: str) -> bool:
    for entry in allowed:
        if "path" in entry and path == entry["path"]:
            return True
        if "glob" in entry and fnmatch.fnmatch(path, entry["glob"]):
            return True
    return False

violations = []
for path in tracked:
    suffix = Path(path).suffix.lower()
    if suffix in forbidden_exts and not is_allowed(path):
        violations.append(f"tracked asset outside allowlist: {path}")

for root in roots:
    p = Path(root)
    files = [p] if p.is_file() else sorted(x for x in p.rglob("*") if x.is_file())
    for file in files:
        try:
            text = file.read_text(encoding="utf-8")
        except Exception:
            continue
        lowered = text.lower()
        for pattern in patterns:
            if pattern.lower() in lowered:
                violations.append(f"forbidden runtime/doc asset reference '{pattern}' in {file.as_posix()}")

if violations:
    print("authenticity asset gate: FAIL")
    for v in violations:
        print(f" - {v}")
    raise SystemExit(1)

print("authenticity asset gate: OK")
PY
