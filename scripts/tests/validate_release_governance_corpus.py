#!/usr/bin/env python3
from pathlib import Path
import sys

checks = {
    'docs/governance/release_process.md': [
        'semver',
        'changelog',
        'signed tag',
        'go/no-go',
        'checksums.txt',
        'sbom',
        'provenance',
        'rollback',
        'smoke-check',
        'watch window',
        'candidate',
        'stable',
    ],
    'docs/release/release_process.md': [
        'source of truth',
        'github release flow',
        'go/no-go',
        'checksums.txt',
        'sbom',
        'блокирующие',
    ],
    'RELEASE_CHECKLIST.md': [
        'current release candidate',
        'mandatory checks',
        'go/no-go decision sheet',
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

print('release governance corpus validation: OK')
