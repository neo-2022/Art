#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import pathlib
import re
import sys

master = pathlib.Path('docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md').read_text(encoding='utf-8')
rows = re.findall(r'\| \[(x| )\] (\d{2}) \| ([^|]+) \|', master)
errors = []
for state, stage, filename in rows:
    filename = filename.strip()
    p = pathlib.Path('docs/source/checklists') / filename
    if not p.exists():
        errors.append(f'stage {stage}: file not found: {filename}')
        continue
    text = p.read_text(encoding='utf-8')
    if state == 'x' and '- [ ]' in text:
        errors.append(f'stage {stage}: marked [x] in MASTER but checklist has open tasks: {filename}')

if errors:
    print('checklist status integrity gate: FAIL')
    for e in errors:
        print(f' - {e}')
    sys.exit(1)

print('checklist status integrity gate: OK')
PY
