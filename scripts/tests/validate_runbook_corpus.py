#!/usr/bin/env python3
from pathlib import Path
import sys

RUNBOOKS = sorted(Path('docs/runbooks').glob('*.md'))
REQUIRED = [
    '## source of truth',
    '## symptoms',
    '## checks',
    '## mitigations',
    '## rollback',
    '## verification',
    '## escalation',
    '## evidence',
    '## owner',
    '## degraded mode',
]
FORBIDDEN = ['## Diagnosis', '## Resolution', '## Symptoms', '## Rollback']

bad = []
for path in RUNBOOKS:
    text = path.read_text()
    lower = text.lower()
    missing = [h for h in REQUIRED if h not in lower]
    forbidden = [h for h in FORBIDDEN if h in text]
    if missing or forbidden:
        bad.append((path.as_posix(), missing, forbidden))

if bad:
    for path, missing, forbidden in bad:
        print(path)
        if missing:
            print('  missing:', ', '.join(missing))
        if forbidden:
            print('  forbidden:', ', '.join(forbidden))
    sys.exit(1)

print(f'runbook corpus validation: OK ({len(RUNBOOKS)} files)')
