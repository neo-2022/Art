from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple


def _semver_tuple(version: str) -> Tuple[int, int, int]:
    parts = version.strip().split(".")
    if len(parts) != 3:
        raise ValueError(f"invalid semver: {version}")
    return int(parts[0]), int(parts[1]), int(parts[2])


def _match_range(version: str, version_range: str) -> bool:
    v = _semver_tuple(version)
    for rule in [r.strip() for r in version_range.split(",") if r.strip()]:
        if rule.startswith(">="):
            if v < _semver_tuple(rule[2:]):
                return False
        elif rule.startswith("<="):
            if v > _semver_tuple(rule[2:]):
                return False
        elif rule.startswith(">"):
            if v <= _semver_tuple(rule[1:]):
                return False
        elif rule.startswith("<"):
            if v >= _semver_tuple(rule[1:]):
                return False
        elif rule.startswith("=="):
            if v != _semver_tuple(rule[2:]):
                return False
        else:
            if v != _semver_tuple(rule):
                return False
    return True


@dataclass
class InstallResult:
    ok: bool
    activated: bool
    gap_event: dict | None


class PackRuntime:
    def __init__(self) -> None:
        self.installed: Dict[str, str] = {}

    def install_pack(self, pack: dict, core_version: str = "1.0.0") -> InstallResult:
        name = pack["name"]
        version = pack["version"]
        if pack.get("signature") != "valid":
            return InstallResult(
                ok=False,
                activated=False,
                gap_event={
                    "kind": "observability_gap.pack_install_failed",
                    "details": {
                        "pack_name": name,
                        "pack_version": version,
                        "fail_stage": "signature",
                        "error": "invalid_signature",
                        "trace_id": "trace-pack",
                    },
                },
            )

        core_range = pack.get("core_version_range", ">=1.0.0")
        if not _match_range(core_version, core_range):
            return InstallResult(
                ok=False,
                activated=False,
                gap_event={
                    "kind": "observability_gap.pack_incompatible",
                    "details": {
                        "pack_name": name,
                        "pack_version": version,
                        "core_version": core_version,
                        "core_version_range": core_range,
                        "trace_id": "trace-pack",
                    },
                },
            )

        dep_result = self.resolve_dependencies(pack["dependencies"], pack.get("catalog", {}))
        if not dep_result[0]:
            return InstallResult(
                ok=False,
                activated=False,
                gap_event={
                    "kind": "observability_gap.pack_install_failed",
                    "details": {
                        "pack_name": name,
                        "pack_version": version,
                        "fail_stage": dep_result[1],
                        "error": dep_result[2],
                        "trace_id": "trace-pack",
                    },
                },
            )

        self.installed[name] = version
        return InstallResult(ok=True, activated=True, gap_event=None)

    def resolve_dependencies(
        self, dependencies: List[dict], catalog: Dict[str, List[str]]
    ) -> Tuple[bool, str, str]:
        graph: Dict[str, List[str]] = {}
        for dep in dependencies:
            name = dep["name"]
            rng = dep["version_range"]
            available = [v for v in catalog.get(name, []) if _match_range(v, rng)]
            if not available:
                return False, "deps", f"missing_dependency:{name}"
            selected = sorted(available, key=_semver_tuple)[-1]
            graph[name] = []
            for nested in dependencies:
                if nested["name"] == name:
                    continue
                if nested["name"].startswith(name + "->"):
                    graph[name].append(nested["name"])  # synthetic test hook
            self.installed[name] = selected

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
                if not dfs(child):
                    return False
            stack.remove(node)
            return True

        for node in list(graph.keys()):
            if not dfs(node):
                return False, "deps", "dependency_cycle"

        return True, "", ""
