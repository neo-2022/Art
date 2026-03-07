#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import json
import os
import pathlib
import subprocess
import sys

try:
    import yaml
except Exception:
    print('PyYAML is required for root decision tree sync gate')
    raise

cfg_path = pathlib.Path('formats/root_decision_tree_dependencies.yaml')
if not cfg_path.exists():
    print('missing root decision tree dependency map')
    sys.exit(1)

cfg = yaml.safe_load(cfg_path.read_text(encoding='utf-8'))
common = [pathlib.Path(p) for p in cfg.get('common_dependents', [])]
roots = cfg.get('roots', [])
if not roots:
    print('empty root decision tree dependency map')
    sys.exit(1)

errors = []
for dep in common:
    if not dep.exists():
        errors.append(f'missing common dependent: {dep.as_posix()}')
for root in roots:
    path = pathlib.Path(root['path'])
    if not path.exists():
        errors.append(f'missing root document: {path.as_posix()}')
    for dep in root.get('extra_dependents', []):
        dep_path = pathlib.Path(dep)
        if not dep_path.exists():
            errors.append(f'missing extra dependent for {path.as_posix()}: {dep_path.as_posix()}')

if errors:
    print('root decision tree sync gate: FAIL')
    for err in errors:
        print(f' - {err}')
    sys.exit(1)


def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()


def detect_range():
    event_path = os.environ.get('GITHUB_EVENT_PATH')
    event_name = os.environ.get('GITHUB_EVENT_NAME', '')
    if event_path and pathlib.Path(event_path).exists():
        event = json.loads(pathlib.Path(event_path).read_text(encoding='utf-8'))
        if event_name == 'pull_request':
            return event['pull_request']['base']['sha'], event['pull_request']['head']['sha']
        if event_name == 'push':
            before = event.get('before')
            after = event.get('after') or os.environ.get('GITHUB_SHA')
            if before and before != '0000000000000000000000000000000000000000' and after:
                return before, after
    try:
        return git('rev-parse', 'HEAD^'), git('rev-parse', 'HEAD')
    except subprocess.CalledProcessError:
        return None, None

base, head = detect_range()
if base and head:
    changed = set(filter(None, git('diff', '--name-only', base, head).splitlines()))
else:
    changed = set()

try:
    changed |= set(filter(None, git('diff', '--name-only', 'HEAD').splitlines()))
    changed |= set(filter(None, git('diff', '--name-only', '--cached').splitlines()))
except subprocess.CalledProcessError:
    pass

if not changed:
    changed = set(filter(None, git('ls-files').splitlines()))

changed_roots = []
for root in roots:
    root_path = root['path']
    if root_path in changed:
        changed_roots.append(root)

if not changed_roots:
    print('root decision tree sync gate: OK (root docs unchanged in range)')
    sys.exit(0)

sync_errors = []
for root in changed_roots:
    root_path = root['path']
    required = [str(p.as_posix()) for p in common] + root.get('extra_dependents', [])
    missing = [dep for dep in required if dep not in changed]
    if missing:
        sync_errors.append((root_path, missing))

if sync_errors:
    print('root decision tree sync gate: FAIL')
    for root_path, missing in sync_errors:
        print(f' - root changed without synced dependents: {root_path}')
        for dep in missing:
            print(f'   * {dep}')
    sys.exit(1)

print('root decision tree sync gate: OK')
PY
