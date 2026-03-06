#!/usr/bin/env bash
set -euo pipefail

BASELINE_FILE="docs/source/innovation_kpi_baseline_v0_2.json"
ACTUAL_FILE="docs/governance/evidence/stage34_step13_innovation_kpi_report.json"
GATE_LOG="docs/governance/evidence/stage34_step13_innovation_kpi_gate.log"

bash scripts/tests/stage34_innovation_kpi_with_artifacts.sh

python3 - "$BASELINE_FILE" "$ACTUAL_FILE" "$GATE_LOG" <<'PY'
import json
import sys
from pathlib import Path

baseline = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
actual = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
gate_log = Path(sys.argv[3])

max_deg = float(baseline['policy']['max_degradation_ratio'])
metrics = ['false_positive_rate', 'runbook_mismatch_rate', 'rollback_rate']

lines = ['stage34 innovation kpi gate']
failed = []
for metric in metrics:
    b = float(baseline['metrics'][metric])
    a = float(actual['metrics'][metric])
    threshold = b * (1.0 + max_deg)
    passed = a <= threshold
    lines.append(f"{metric}: baseline={b:.6f} actual={a:.6f} threshold={threshold:.6f} pass={passed}")
    if not passed:
        failed.append(metric)

if failed:
    lines.append('status=FAIL')
    lines.append('failed_metrics=' + ','.join(failed))
    gate_log.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(gate_log.read_text(encoding='utf-8'), end='')
    raise SystemExit(1)

lines.append('status=PASS')
gate_log.write_text('\n'.join(lines) + '\n', encoding='utf-8')
print(gate_log.read_text(encoding='utf-8'), end='')
PY
