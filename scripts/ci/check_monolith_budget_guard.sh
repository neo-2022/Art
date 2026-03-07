#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception:
    print('PyYAML is required for monolith budget guard')
    raise

budget_path = Path('formats/monolith_budget_guard_v0_2.yaml')
doc_path = Path('docs/source/monolith_budget_guard_v0_2.md')
gap_doc = Path('docs/governance/observability_gap_registry.md')
defect_md = Path('docs/testing/defect_remediation_control_matrix_v0_2.md')
defect_yaml_path = Path('formats/defect_remediation_control_matrix_v0_2.yaml')
master = Path('docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md')
trace = Path('docs/source/checklists/TRACEABILITY_V0_2.md')
constitution = Path('docs/source/FOUNDATION_CONSTITUTION_V0_2.md')
history = Path('docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md')

for required in [budget_path, doc_path, gap_doc, defect_md, defect_yaml_path, master, trace, constitution, history]:
    if not required.exists() or required.stat().st_size == 0:
        print(f'missing required file: {required}')
        sys.exit(1)

budget = yaml.safe_load(budget_path.read_text(encoding='utf-8'))
items = budget.get('critical_files', [])
if not items:
    print('monolith budget guard: no critical_files configured')
    sys.exit(1)

doc_text = doc_path.read_text(encoding='utf-8')
gap_text = gap_doc.read_text(encoding='utf-8')
defect_text = defect_md.read_text(encoding='utf-8')
defect_yaml = yaml.safe_load(defect_yaml_path.read_text(encoding='utf-8'))
master_text = master.read_text(encoding='utf-8')
trace_text = trace.read_text(encoding='utf-8')
constitution_text = constitution.read_text(encoding='utf-8')
history_text = history.read_text(encoding='utf-8')

defect_yaml_ids = {item['id'] for item in defect_yaml.get('defects', [])}
violations = []

for item in items:
    path = Path(item['path'])
    if not path.exists():
        violations.append(f'missing budget target: {path}')
        continue
    actual = sum(1 for _ in path.open('r', encoding='utf-8'))
    expected = int(item['current_lines'])
    budget_lines = int(item['budget_lines'])
    if actual != expected:
        violations.append(f'line count drift for {path}: yaml={expected}, actual={actual}')
    if actual > budget_lines:
        violations.append(f'budget exceeded for {path}: actual={actual}, budget={budget_lines}')
    if str(path) not in doc_text:
        violations.append(f'doc missing budget target reference: {path}')
    for defect_id in item.get('defect_ids', []):
        if defect_id not in defect_text or defect_id not in defect_yaml_ids:
            violations.append(f'defect mapping missing for {path}: {defect_id}')

required_phrases = [
    'Monolith Budget Guard',
    'observability_gap.monolith_budget_exceeded',
    'formats/monolith_budget_guard_v0_2.yaml',
    'scripts/ci/check_monolith_budget_guard.sh',
]
for phrase in required_phrases:
    if phrase not in doc_text:
        violations.append(f'monolith budget doc missing phrase: {phrase}')

if '| observability_gap.monolith_budget_exceeded |' not in gap_text:
    violations.append('gap registry missing observability_gap.monolith_budget_exceeded')

for text_name, text in [('master', master_text), ('traceability', trace_text), ('constitution', constitution_text)]:
    if 'docs/source/monolith_budget_guard_v0_2.md' not in text:
        violations.append(f'{text_name} missing monolith budget doc reference')

if violations:
    print('monolith budget guard: FAIL')
    for violation in violations:
        print(f' - {violation}')
    sys.exit(1)

print('monolith budget guard: OK')
PY
