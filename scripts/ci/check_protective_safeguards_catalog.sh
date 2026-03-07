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
    print('PyYAML is required for protective safeguards catalog gate')
    raise

catalog_md = Path('docs/source/protective_safeguards_catalog_v0_2.md')
catalog_yaml = Path('formats/protective_safeguards_catalog_v0_2.yaml')
constitution = Path('docs/source/FOUNDATION_CONSTITUTION_V0_2.md')
history = Path('docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md')
risk_doc = Path('docs/source/risk_register_v0_2.md')
gap_doc = Path('docs/governance/observability_gap_registry.md')
defect_md = Path('docs/testing/defect_remediation_control_matrix_v0_2.md')
defect_yaml = Path('formats/defect_remediation_control_matrix_v0_2.yaml')
master = Path('docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md')
trace = Path('docs/source/checklists/TRACEABILITY_V0_2.md')

required = [catalog_md, catalog_yaml, constitution, history, risk_doc, gap_doc, defect_md, defect_yaml, master, trace]
for path in required:
    if not path.exists() or path.stat().st_size == 0:
        print(f'missing required file: {path}')
        sys.exit(1)

catalog = yaml.safe_load(catalog_yaml.read_text(encoding='utf-8'))
safeguards = catalog.get('safeguards', [])
if not safeguards:
    print('empty protective safeguards catalog')
    sys.exit(1)

constitution_text = constitution.read_text(encoding='utf-8')
history_text = history.read_text(encoding='utf-8')
risk_text = risk_doc.read_text(encoding='utf-8')
gap_text = gap_doc.read_text(encoding='utf-8')
defect_text = defect_md.read_text(encoding='utf-8')
defect_yaml_catalog = yaml.safe_load(defect_yaml.read_text(encoding='utf-8'))
master_text = master.read_text(encoding='utf-8')
trace_text = trace.read_text(encoding='utf-8')
catalog_md_text = catalog_md.read_text(encoding='utf-8')

defect_yaml_ids = {item['id'] for item in defect_yaml_catalog.get('defects', [])}
risk_ids = set()
for line in risk_text.splitlines():
    if line.startswith('| R'):
        risk_ids.add(line.split('|')[1].strip())

for item in safeguards:
    doc = item['doc']
    if doc not in catalog_md_text:
        print(f'catalog markdown missing doc reference: {doc}')
        sys.exit(1)
    if not Path(doc).exists():
        print(f'safeguard doc missing: {doc}')
        sys.exit(1)
    for runbook in item.get('runbooks', []):
        if not Path(runbook).exists():
            print(f'safeguard runbook missing: {runbook}')
            sys.exit(1)
    for gap in item.get('gaps', []):
        if f'| {gap} |' not in gap_text:
            print(f'gap registry missing: {gap}')
            sys.exit(1)
    for defect_id in item.get('defects', []):
        if defect_id not in defect_text:
            print(f'defect markdown mapping missing for {doc}: {defect_id}')
            sys.exit(1)
        if defect_id not in defect_yaml_ids:
            print(f'defect yaml mapping missing for {doc}: {defect_id}')
            sys.exit(1)
    for risk_id in item.get('risks', []):
        if risk_id not in risk_ids:
            print(f'risk register mapping missing for {doc}: {risk_id}')
            sys.exit(1)
    if doc not in master_text:
        print(f'master checklist missing safeguard reference: {doc}')
        sys.exit(1)
    if doc not in trace_text:
        print(f'traceability missing safeguard reference: {doc}')
        sys.exit(1)
    if doc not in constitution_text:
        print(f'constitution missing safeguard reference: {doc}')
        sys.exit(1)

for required_phrase in (
    'Storage Pressure Protection Law',
    'Startup Configuration Fail-Closed Law',
    'Queue Integrity And Anti-Loop Law',
    'Guard Self-Observability Law',
    'Expanded Protective Safeguards Register',
):
    if required_phrase not in constitution_text:
        print(f'constitution missing: {required_phrase}')
        sys.exit(1)

for required_phrase in (
    'Storage pressure / disk exhaustion protection',
    'Startup configuration fail-closed validator',
    'Queue integrity / duplicate / anti-loop protection',
    'Guard self-observability / self-test',
    'Action execution safety guard',
    'Agent identity / enrollment / relay trust',
    'Release truth enforcement',
    'Authenticity / copyright-safe baseline',
    'Regulatory claims drift control',
    'Monolith budget guard',
    'Test strength guard',
    'Documentation drift control',
):
    if required_phrase not in history_text:
        print(f'history missing: {required_phrase}')
        sys.exit(1)

print('protective safeguards catalog gate: OK')
PY
