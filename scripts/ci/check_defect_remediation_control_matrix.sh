#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import pathlib
import re
import sys

try:
    import yaml
except Exception:
    print('PyYAML is required for defect remediation control matrix gate')
    raise

yaml_path = pathlib.Path('formats/defect_remediation_control_matrix_v0_2.yaml')
md_path = pathlib.Path('docs/testing/defect_remediation_control_matrix_v0_2.md')
reopen_path = pathlib.Path('docs/testing/stage_reopening_matrix_v0_2.md')
master_path = pathlib.Path('docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md')

for p in (yaml_path, md_path, reopen_path, master_path):
    if not p.exists():
        print(f'missing required file: {p}')
        sys.exit(1)

data = yaml.safe_load(yaml_path.read_text(encoding='utf-8'))
defects = data.get('defects', [])
if not defects:
    print('empty defect remediation control matrix yaml')
    sys.exit(1)

ids = [d['id'] for d in defects]
if len(ids) != len(set(ids)):
    print('duplicate defect ids in yaml')
    sys.exit(1)

orders = [int(d['execution_order']) for d in defects]
if sorted(orders) != list(range(1, len(defects) + 1)):
    print('execution_order must be contiguous starting from 1')
    sys.exit(1)

id_set = set(ids)
covered_stages = set()
errors = []
for defect in defects:
    if defect.get('id') not in id_set:
        errors.append(f"invalid id: {defect.get('id')}")
    for dep in defect.get('execution_dependencies', []):
        if dep not in id_set:
            errors.append(f"{defect['id']} depends on unknown defect {dep}")
    for checklist in defect.get('target_checklists', []):
        path = pathlib.Path(checklist)
        if not path.exists():
            errors.append(f"{defect['id']} references missing checklist {checklist}")
    for stage in defect.get('affected_stages', []):
        covered_stages.add(str(stage))

md_text = md_path.read_text(encoding='utf-8')
for defect_id in ids:
    if not re.search(rf'^### \[[ x]\] {re.escape(defect_id)}\b', md_text, re.M):
        errors.append(f"markdown control matrix missing section for {defect_id}")

reopen_text = reopen_path.read_text(encoding='utf-8').splitlines()
open_stages = set()
for line in reopen_text:
    m = re.match(r'^\| `([^`]+)` \| `(OPEN|REOPEN)` \|', line)
    if not m:
        continue
    raw = m.group(1)
    if '..' in raw:
        start, end = raw.split('..', 1)
        for i in range(int(start), int(end) + 1):
            open_stages.add(str(i))
    else:
        open_stages.add(raw)

missing_from_matrix = sorted(open_stages - covered_stages, key=lambda x: int(x))
if missing_from_matrix:
    errors.append('reopened/open stages missing from defect control matrix: ' + ', '.join(missing_from_matrix))

master_text = master_path.read_text(encoding='utf-8')
for ref in (
    'docs/testing/defect_remediation_control_matrix_v0_2.md',
    'formats/defect_remediation_control_matrix_v0_2.yaml',
):
    if ref not in master_text:
        errors.append(f'master checklist missing reference: {ref}')

if errors:
    print('defect remediation control matrix gate: FAIL')
    for err in errors:
        print(f' - {err}')
    sys.exit(1)

print('defect remediation control matrix gate: OK')
PY
