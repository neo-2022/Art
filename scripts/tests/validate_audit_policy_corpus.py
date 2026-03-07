#!/usr/bin/env python3
from pathlib import Path
import sys

text = Path('docs/governance/audit_policy.md').read_text().lower()
needles = [
    'immutable', 'неизменяем', 'append-only',
    'timestamp', 'actor', 'action', 'target', 'result', 'evidence_ref',
    'не менее 1 года', 'роль', 'идентификатор', 'actor_role', 'actor_id', 'actor_origin',
    'manual', 'automatic', 'mcp', 'pre-write redaction', 'privacy.redaction_applied'
]
missing = [n for n in needles if n not in text]
if missing:
    print('missing:', ', '.join(missing))
    sys.exit(1)
print('audit policy corpus validation: OK')
