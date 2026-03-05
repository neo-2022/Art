from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple
import hashlib


def _semver_tuple(version: str) -> Tuple[int, int, int]:
    parts = version.strip().split('.')
    if len(parts) != 3:
        raise ValueError(f"invalid semver: {version}")
    return int(parts[0]), int(parts[1]), int(parts[2])


def _match_range(version: str, version_range: str) -> bool:
    v = _semver_tuple(version)
    for rule in [r.strip() for r in version_range.split(',') if r.strip()]:
        if rule.startswith('>='):
            if v < _semver_tuple(rule[2:]):
                return False
        elif rule.startswith('<='):
            if v > _semver_tuple(rule[2:]):
                return False
        elif rule.startswith('>'):
            if v <= _semver_tuple(rule[1:]):
                return False
        elif rule.startswith('<'):
            if v >= _semver_tuple(rule[1:]):
                return False
        elif rule.startswith('=='):
            if v != _semver_tuple(rule[2:]):
                return False
        else:
            if v != _semver_tuple(rule):
                return False
    return True


def _strip_quotes(value: str) -> str:
    v = value.strip()
    if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
        return v[1:-1]
    return v


@dataclass
class InstallResult:
    ok: bool
    activated: bool
    gap_event: dict | None


class PackRuntime:
    def __init__(self) -> None:
        self.installed: Dict[str, str] = {}

    def _gap(self, kind: str, *, pack_name: str, pack_version: str, fail_stage: str, error: str, extra: dict | None = None) -> dict:
        details = {
            'pack_name': pack_name,
            'pack_version': pack_version,
            'fail_stage': fail_stage,
            'error': error,
            'trace_id': 'trace-pack',
        }
        if extra:
            details.update(extra)
        return {'kind': kind, 'details': details}

    def _parse_manifest(self, manifest_path: Path) -> dict:
        lines = [line.rstrip('\n') for line in manifest_path.read_text(encoding='utf-8').splitlines()]
        data: dict = {}
        i = 0
        while i < len(lines):
            line = lines[i]
            if not line.strip() or line.strip().startswith('#'):
                i += 1
                continue
            if line.startswith('name:'):
                data['name'] = _strip_quotes(line.split(':', 1)[1])
                i += 1
                continue
            if line.startswith('version:'):
                data['version'] = _strip_quotes(line.split(':', 1)[1])
                i += 1
                continue
            if line.startswith('core_version_range:'):
                data['core_version_range'] = _strip_quotes(line.split(':', 1)[1])
                i += 1
                continue
            if line.startswith('dependencies:'):
                deps = []
                i += 1
                while i < len(lines) and lines[i].startswith('  - '):
                    dep = {}
                    first = lines[i][4:]
                    if ':' in first:
                        k, v = first.split(':', 1)
                        dep[k.strip()] = _strip_quotes(v)
                    i += 1
                    while i < len(lines) and lines[i].startswith('    '):
                        k, v = lines[i].strip().split(':', 1)
                        value = _strip_quotes(v)
                        if k == 'requires':
                            dep[k] = [x.strip() for x in value.split(',') if x.strip()]
                        else:
                            dep[k] = value
                        i += 1
                    deps.append(dep)
                data['dependencies'] = deps
                continue
            if line.startswith('entrypoints:'):
                entrypoints: List[str] = []
                i += 1
                while i < len(lines) and lines[i].startswith('  - '):
                    entrypoints.append(_strip_quotes(lines[i][4:]))
                    i += 1
                data['entrypoints'] = entrypoints
                continue
            i += 1
        return data

    def _verify_signature(self, manifest_path: Path, signature_path: Path) -> bool:
        content = signature_path.read_text(encoding='utf-8').strip()
        if not content:
            return False
        expected = content.split()[0].strip()
        actual = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
        return actual == expected

    def resolve_dependencies(self, dependencies: List[dict], catalog: Dict[str, List[str]]) -> Tuple[bool, str, str]:
        graph: Dict[str, List[str]] = {}
        for dep in dependencies:
            name = dep.get('name', '')
            rng = dep.get('version_range', '')
            if not name or not rng:
                return False, 'layout', f'invalid_dependency:{dep}'
            available = [v for v in catalog.get(name, []) if _match_range(v, rng)]
            if not available:
                return False, 'deps', f'missing_dependency:{name}'
            selected = sorted(available, key=_semver_tuple)[-1]
            self.installed[name] = selected
            req = dep.get('requires', [])
            if isinstance(req, list):
                graph[name] = req
            else:
                graph[name] = []

        seen = set()
        stack = set()

        def dfs(node: str) -> bool:
            if node in stack:
                return False
            if node in seen:
                return True
            seen.add(node)
            stack.add(node)
            for child in graph.get(node, []):
                if child in graph and not dfs(child):
                    return False
            stack.remove(node)
            return True

        for node in list(graph.keys()):
            if not dfs(node):
                return False, 'deps', 'dependency_cycle'

        return True, '', ''

    def install_pack_from_dir(self, pack_dir: Path, *, catalog: Dict[str, List[str]], core_version: str = '1.0.0') -> InstallResult:
        try:
            manifest_path = pack_dir / 'manifest.yaml'
            payload_dir = pack_dir / 'payload'
            signature_path = pack_dir / 'signatures' / 'manifest.sha256'
            if not manifest_path.exists() or not payload_dir.exists() or not signature_path.exists():
                return InstallResult(
                    ok=False,
                    activated=False,
                    gap_event=self._gap(
                        'observability_gap.pack_install_failed',
                        pack_name=pack_dir.name,
                        pack_version='unknown',
                        fail_stage='layout',
                        error='missing_manifest_payload_or_signature',
                    ),
                )

            manifest = self._parse_manifest(manifest_path)
            name = manifest.get('name', pack_dir.name)
            version = manifest.get('version', 'unknown')

            for key in ('name', 'version', 'dependencies', 'entrypoints'):
                if key not in manifest:
                    return InstallResult(
                        ok=False,
                        activated=False,
                        gap_event=self._gap(
                            'observability_gap.pack_install_failed',
                            pack_name=name,
                            pack_version=version,
                            fail_stage='layout',
                            error=f'missing_field:{key}',
                        ),
                    )

            try:
                _semver_tuple(version)
            except Exception:
                return InstallResult(
                    ok=False,
                    activated=False,
                    gap_event=self._gap(
                        'observability_gap.pack_install_failed',
                        pack_name=name,
                        pack_version=version,
                        fail_stage='layout',
                        error='invalid_semver',
                    ),
                )

            if not self._verify_signature(manifest_path, signature_path):
                return InstallResult(
                    ok=False,
                    activated=False,
                    gap_event=self._gap(
                        'observability_gap.pack_install_failed',
                        pack_name=name,
                        pack_version=version,
                        fail_stage='signature',
                        error='invalid_signature',
                    ),
                )

            core_range = manifest.get('core_version_range', '>=1.0.0')
            if not _match_range(core_version, core_range):
                return InstallResult(
                    ok=False,
                    activated=False,
                    gap_event=self._gap(
                        'observability_gap.pack_incompatible',
                        pack_name=name,
                        pack_version=version,
                        fail_stage='activate',
                        error='core_version_mismatch',
                        extra={
                            'core_version': core_version,
                            'core_version_range': core_range,
                        },
                    ),
                )

            dep_result = self.resolve_dependencies(manifest['dependencies'], catalog)
            if not dep_result[0]:
                return InstallResult(
                    ok=False,
                    activated=False,
                    gap_event=self._gap(
                        'observability_gap.pack_install_failed',
                        pack_name=name,
                        pack_version=version,
                        fail_stage=dep_result[1],
                        error=dep_result[2],
                    ),
                )

            for entry in manifest['entrypoints']:
                if not (pack_dir / entry).exists():
                    return InstallResult(
                        ok=False,
                        activated=False,
                        gap_event=self._gap(
                            'observability_gap.pack_install_failed',
                            pack_name=name,
                            pack_version=version,
                            fail_stage='layout',
                            error=f'missing_entrypoint:{entry}',
                        ),
                    )

            self.installed[name] = version
            return InstallResult(ok=True, activated=True, gap_event=None)
        except Exception as exc:
            return InstallResult(
                ok=False,
                activated=False,
                gap_event=self._gap(
                    'observability_gap.pack_install_failed',
                    pack_name=pack_dir.name,
                    pack_version='unknown',
                    fail_stage='io',
                    error=str(exc),
                ),
            )
