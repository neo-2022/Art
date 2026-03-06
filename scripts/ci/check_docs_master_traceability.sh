#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import pathlib
import fnmatch
import sys

try:
    import yaml
except Exception:
    print('PyYAML is required for docs traceability gate')
    raise

matrix_path = pathlib.Path('docs/governance/docs_traceability_matrix.yaml')
if not matrix_path.exists():
    print('missing docs traceability matrix')
    sys.exit(1)

matrix = yaml.safe_load(matrix_path.read_text(encoding='utf-8'))
master = pathlib.Path(matrix['master_checklist'])
if not master.exists():
    print(f"missing master checklist: {master}")
    sys.exit(1)
master_text = master.read_text(encoding='utf-8')

mappings = matrix.get('mappings', [])
if not mappings:
    print('empty mappings in docs traceability matrix')
    sys.exit(1)

errors = []
for m in mappings:
    p = pathlib.Path(m['checklist'])
    if not p.exists():
        errors.append(f"mapping references missing checklist: {p}")
        continue
    name = p.name
    if name != master.name and name not in master_text:
        errors.append(f"checklist not referenced by master table: {name}")

tracked = [pathlib.Path('README.md'), pathlib.Path('SECURITY.md')]
tracked += sorted(pathlib.Path('docs').rglob('*.md'))
tracked = [p for p in tracked if p.is_file()]

for f in tracked:
    rel = str(f.as_posix())
    matched = None
    for m in mappings:
        if fnmatch.fnmatch(rel, m['pattern']):
            matched = m
            break
    if matched is None:
        errors.append(f"unmapped documentation file: {rel}")

if errors:
    print('docs master traceability gate: FAIL')
    for err in errors:
        print(f' - {err}')
    sys.exit(1)

print('docs master traceability gate: OK')
PY
