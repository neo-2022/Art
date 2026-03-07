#!/usr/bin/env python3
from pathlib import Path
import sys

checks = {
    'docs/governance/postmortem_policy.md': [
        'blameless',
        'owner follow-ups',
        'evidence',
        'timeline',
        'blast radius',
        'root-cause descent',
        'counterfactual',
        'verification',
    ],
    'docs/governance/postmortem_template.md': [
        '## impact',
        '## blast radius',
        '## timeline',
        '## detection and containment',
        '## root cause',
        '## contributing factors',
        '## degraded mode and rollback',
        '## what went well',
        '## what went wrong',
        '## counterfactuals',
        '## actions',
        '## verification plan',
        '## evidence',
        '## owner follow-ups',
    ],
}

errors = []
for path, needles in checks.items():
    text = Path(path).read_text().lower()
    missing = [needle for needle in needles if needle.lower() not in text]
    if missing:
        errors.append((path, missing))

if errors:
    for path, missing in errors:
        print(path)
        print('  missing:', ', '.join(missing))
    sys.exit(1)

print('postmortem corpus validation: OK')
