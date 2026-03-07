#!/usr/bin/env python3
from pathlib import Path
import sys

codeowners = Path('.github/CODEOWNERS').read_text()
pr_template = Path('.github/pull_request_template.md').read_text()

errors = []
for required in [
    '@neo-2022 @2art260679-rgb',
    '.github/workflows/*',
    'core/**',
    'agent/**',
    'apps/**',
    'packages/**',
    'docs/source/**',
    'docs/testing/**',
    'formats/**',
    'packs/**',
]:
    if required not in codeowners:
        errors.append(f'CODEOWNERS missing: {required}')

for section in [
    '## Evidence',
    '## Adversarial / negative проверка',
    '## Исключённые альтернативные причины',
    '## Rollback / degraded mode',
    '## Чек-лист / этап',
]:
    if section not in pr_template:
        errors.append(f'PR template missing: {section}')

for checkbox in [
    'Evidence приложен и достаточен для повторной проверки',
    'Hostile / negative-path проверка выполнена',
    'Альтернативные причины исключены',
]:
    if checkbox not in pr_template:
        errors.append(f'PR template missing checkbox: {checkbox}')

if errors:
    print('\n'.join(errors))
    sys.exit(1)

print('governance enforce artifacts: OK')
