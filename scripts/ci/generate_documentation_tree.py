#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Tuple

try:
    import yaml
except Exception as exc:  # pragma: no cover
    print('PyYAML is required for documentation tree generator', file=sys.stderr)
    raise

RE_LINK = re.compile(r'\[[^\]]+\]\(([^)]+)\)')


@dataclass
class Node:
    path: str
    lines: int
    root_influence: bool
    children: List[str] = field(default_factory=list)
    incoming: List[str] = field(default_factory=list)


def read_rules(root_dir: Path) -> dict:
    rules_path = root_dir / 'formats' / 'documentation_tree_rules_v0_2.yaml'
    return yaml.safe_load(rules_path.read_text(encoding='utf-8'))


def read_root_tree_dependencies(root_dir: Path) -> set[str]:
    deps_path = root_dir / 'formats' / 'root_decision_tree_dependencies.yaml'
    if not deps_path.exists():
        return set()
    data = yaml.safe_load(deps_path.read_text(encoding='utf-8'))
    root_paths = {entry['path'] for entry in data.get('roots', [])}
    common = set(data.get('common_dependents', []))
    return root_paths | common


def normalize_link(base_file: Path, link: str, root_dir: Path, allowed_exts: Set[str], excluded: Set[str]) -> Tuple[str | None, str | None]:
    if not link or link.startswith('#'):
        return None, None
    if '://' in link:
        return None, None
    clean = link.split('#', 1)[0].split('?', 1)[0].strip()
    if not clean:
        return None, None
    target = (base_file.parent / clean).resolve()
    try:
        rel = target.relative_to(root_dir.resolve())
    except ValueError:
        return None, None
    rel_str = rel.as_posix()
    if target.is_dir():
        return None, rel_str
    if rel_str in excluded:
        return None, None
    if target.suffix.lower() not in allowed_exts:
        return None, None
    if not target.exists():
        return None, rel_str
    return rel_str, None


def file_line_count(path: Path) -> int:
    return sum(1 for _ in path.open('r', encoding='utf-8'))


def build_tree(root_dir: Path, rules: dict) -> Tuple[dict, str]:
    root_file = rules['root']
    allowed_exts = set(rules.get('allowed_extensions', []))
    excluded = set(rules.get('excluded_from_graph', []))
    root_influence = (set(rules.get('root_influence', [])) | read_root_tree_dependencies(root_dir)) - excluded

    queue = deque([root_file])
    seen: Set[str] = set()
    nodes: Dict[str, Node] = {}
    omitted_directory_links: Dict[str, List[str]] = {}
    missing_targets: Dict[str, List[str]] = {}
    total_links = 0

    while queue:
        rel_path = queue.popleft()
        if rel_path in seen:
            continue
        seen.add(rel_path)
        path = root_dir / rel_path
        lines = file_line_count(path)
        node = nodes.setdefault(rel_path, Node(rel_path, lines, rel_path in root_influence))

        if path.suffix.lower() != '.md':
            continue

        text = path.read_text(encoding='utf-8')
        for raw_link in RE_LINK.findall(text):
            total_links += 1
            normalized, directory_rel = normalize_link(path, raw_link, root_dir, allowed_exts, excluded)
            if directory_rel:
                omitted_directory_links.setdefault(rel_path, []).append(directory_rel)
                continue
            if not normalized:
                continue
            target = root_dir / normalized
            if not target.exists():
                missing_targets.setdefault(rel_path, []).append(normalized)
                continue
            child = nodes.setdefault(normalized, Node(normalized, file_line_count(target), normalized in root_influence))
            if normalized not in node.children:
                node.children.append(normalized)
            if rel_path not in child.incoming:
                child.incoming.append(rel_path)
            queue.append(normalized)

    root_children = nodes[root_file].children if root_file in nodes else []
    total_file_links_in_tree = sum(len(node.children) for node in nodes.values())
    total_lines_in_tree = sum(node.lines for node in nodes.values())
    tree = {
        'version': '1.0',
        'status': 'ACTIVE',
        'root': root_file,
        'total_documents': len(nodes),
        'total_markdown_links_scanned': total_links,
        'total_file_links_in_tree': total_file_links_in_tree,
        'total_lines_in_tree': total_lines_in_tree,
        'root_direct_children': len(root_children),
        'root_influence_documents': sorted(root_influence),
        'excluded_from_graph': sorted(excluded),
        'nodes': [
            {
                'path': n.path,
                'lines': n.lines,
                'root_influence': n.root_influence,
                'children': n.children,
                'incoming': n.incoming,
            }
            for n in sorted(nodes.values(), key=lambda item: item.path)
        ],
        'omitted_directory_links': omitted_directory_links,
        'missing_targets': missing_targets,
    }

    mermaid_lines = ['graph TD']
    ids: Dict[str, str] = {}
    for idx, path in enumerate(sorted(nodes.keys()), start=1):
        ids[path] = f'N{idx}'
    for path, node in sorted(nodes.items()):
        label = f"{path}\\n{node.lines} строк"
        if node.root_influence:
            label += '\\nROOT-INFLUENCE'
        mermaid_lines.append(f"    {ids[path]}[\"{label}\"]")
    for path, node in sorted(nodes.items()):
        for child in node.children:
            mermaid_lines.append(f"    {ids[path]} --> {ids[child]}")
    mermaid = '\n'.join(mermaid_lines)

    return tree, mermaid




def rel_link(output_rel: str, target_rel: str) -> str:
    start = Path(output_rel).parent.as_posix()
    return os.path.relpath(target_rel, start=start).replace('\\', '/')

def build_tree_lines(root: str, nodes_by_path: Dict[str, dict], output_rel: str, prefix: str = '', visited: Set[str] | None = None) -> List[str]:
    if visited is None:
        visited = set()
    node = nodes_by_path[root]
    marker = ' `ROOT-INFLUENCE`' if node['root_influence'] else ''
    line = f"{prefix}- [`{root}`]({rel_link(output_rel, root)}) — `{node['lines']}` строк{marker}"
    lines = [line]
    if root in visited:
        lines[-1] += ' `REUSED-LINK`'
        return lines
    visited.add(root)
    for child in node['children']:
        lines.extend(build_tree_lines(child, nodes_by_path, output_rel, prefix + '  ', visited.copy()))
    return lines


def render_markdown(tree: dict, mermaid: str, output_rel: str, lang: str = "ru") -> str:
    nodes_by_path = {node['path']: node for node in tree['nodes']}
    root = tree['root']
    root_node = nodes_by_path[root]
    tree_lines = build_tree_lines(root, nodes_by_path, output_rel)
    omitted = tree.get('omitted_directory_links', {})
    missing = tree.get('missing_targets', {})
    excluded = tree.get('excluded_from_graph', [])
    root_influence_lines = []
    for path in tree['root_influence_documents']:
        node = nodes_by_path.get(path)
        if node:
            root_influence_lines.append(f"- [`{path}`]({rel_link(output_rel, path)}) — `{node['lines']}` строк")
        else:
            root_influence_lines.append(f"- `{path}` — `НЕ ПОПАЛ В ДЕРЕВО`")

    omitted_lines = ['- нет'] if not omitted else [f"- `{src}` -> `{target}`" for src, targets in sorted(omitted.items()) for target in targets]
    missing_lines = ['- нет'] if not missing else [f"- `{src}` -> `{target}`" for src, targets in sorted(missing.items()) for target in targets]

    return f"""# Графическое дерево документации Art

## Source of truth
- [`{rel_link(output_rel, 'README.md')}`]({rel_link(output_rel, 'README.md')})
- [`{rel_link(output_rel, 'formats/documentation_tree_rules_v0_2.yaml')}`]({rel_link(output_rel, 'formats/documentation_tree_rules_v0_2.yaml')})
- [`{rel_link(output_rel, 'formats/documentation_tree_v0_2.yaml')}`]({rel_link(output_rel, 'formats/documentation_tree_v0_2.yaml')})
- [`{rel_link(output_rel, 'scripts/ci/generate_documentation_tree.py')}`]({rel_link(output_rel, 'scripts/ci/generate_documentation_tree.py')})
- [`{rel_link(output_rel, 'scripts/ci/check_documentation_tree_sync.sh')}`]({rel_link(output_rel, 'scripts/ci/check_documentation_tree_sync.sh')})

## Назначение
Это отдельный навигационно-контрольный слой документации.

Он не заменяет дерево принятия решений проекта.
Он показывает:
- как документация реально связана от корневого `README.md`;
- сколько документов входит в дерево;
- сколько строк в каждом документе;
- какие документы прямо влияют на корневой `README.md`;
- где возможен drift, который требует обновить корневой `README.md`.

## Что даёт этот слой
- быстрый вход в документацию без потери контекста;
- защиту от неучтённых изменений в ключевых документах;
- наглядную карту зависимостей;
- контроль того, что изменения смыслообразующих документов не проходят мимо корневого `README.md`.

## Сводка
- Корень дерева: [`{rel_link(output_rel, root)}`]({rel_link(output_rel, root)})
- Строк в корневом `README.md`: `{root_node['lines']}`
- Уникальных документов в дереве: `{tree['total_documents']}`
- Общих строк во всём дереве: `{tree['total_lines_in_tree']}`
- Всех файловых связей в дереве: `{tree['total_file_links_in_tree']}`
- Просканированных markdown-ссылок: `{tree['total_markdown_links_scanned']}`
- Прямых дочерних ссылок у корня: `{tree['root_direct_children']}`
- Документов с признаком `ROOT-INFLUENCE`: `{len(tree['root_influence_documents'])}`

## Граф
```mermaid
{mermaid}
```

## Дерево ссылок
{"\n".join(tree_lines)}

## Документы, влияющие на корневой README
Если изменяется любой документ из этого списка, а `README.md` не изменён, CI подаёт сигнал о рассинхроне.

{"\n".join(root_influence_lines)}

## Пропущенные directory-ссылки
Это ссылки в markdown на каталоги, а не на отдельные файлы. Они не включаются в дерево как отдельные вершины.

{"\n".join(omitted_lines)}

## Missing targets
Если здесь появится запись, значит в документации есть ссылка на файл, который не найден.

{"\n".join(missing_lines)}

## Статус
- Статус дерева: `ACTIVE`
- Корень документационного дерева: `README.md`
- Контроль рассинхрона: `ENABLED`
"""


def git_changed_files(root_dir: Path) -> Set[str]:
    def git(*args: str) -> List[str]:
        out = subprocess.check_output(['git', *args], cwd=root_dir, text=True)
        return [line for line in out.splitlines() if line]
    changed: Set[str] = set()
    try:
        changed.update(git('diff', '--name-only', 'HEAD'))
        changed.update(git('diff', '--name-only', '--cached'))
        for line in git('status', '--porcelain'):
            if len(line) >= 4:
                changed.add(line[3:].strip())
    except subprocess.CalledProcessError:
        pass
    return changed


def write_if_changed(path: Path, content: str) -> bool:
    old = path.read_text(encoding='utf-8') if path.exists() else None
    if old == content:
        return False
    path.write_text(content, encoding='utf-8')
    return True


def load_existing_tree(path: Path) -> dict:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text(encoding='utf-8')) or {}


def node_map(tree: dict) -> Dict[str, dict]:
    return {node['path']: node for node in tree.get('nodes', [])}


def format_dependency_targets(path: str, new_nodes: Dict[str, dict]) -> str:
    incoming = new_nodes.get(path, {}).get('incoming', [])
    if not incoming:
        return 'нет входящих зависимостей в дереве'
    return ', '.join(incoming[:5]) + (' ...' if len(incoming) > 5 else '')


def report_tree_drift(current_tree: dict, new_tree: dict) -> None:
    current_nodes = node_map(current_tree)
    new_nodes = node_map(new_tree)
    current_total_lines = current_tree.get('total_lines_in_tree', sum(node.get('lines', 0) for node in current_nodes.values()))
    new_total_lines = new_tree.get('total_lines_in_tree', sum(node.get('lines', 0) for node in new_nodes.values()))
    print(f' - total_lines_in_tree: {current_total_lines} -> {new_total_lines}')

    changed_paths = []
    for path in sorted(set(current_nodes) | set(new_nodes)):
        old_lines = current_nodes.get(path, {}).get('lines')
        new_lines = new_nodes.get(path, {}).get('lines')
        if old_lines != new_lines:
            changed_paths.append((path, old_lines, new_lines))

    if not changed_paths:
        print(' - line counts changed indirectly (структура дерева или root-influence набор)')
        return

    print(' - changed document line counts:')
    for path, old_lines, new_lines in changed_paths[:25]:
        deps = format_dependency_targets(path, new_nodes)
        print(f'   * {path}: {old_lines} -> {new_lines}; зависит от/влияет через: {deps}')
    if len(changed_paths) > 25:
        print(f'   ... ещё {len(changed_paths) - 25} файлов')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()

    root_dir = Path(__file__).resolve().parents[2]
    rules = read_rules(root_dir)
    tree, mermaid = build_tree(root_dir, rules)
    md = render_markdown(tree, mermaid, rules['output_markdown'], 'ru')
    md_en = render_markdown(tree, mermaid, rules['output_markdown_en'], 'en')
    yaml_content = yaml.safe_dump(tree, sort_keys=False, allow_unicode=True)

    out_md = root_dir / rules['output_markdown']
    out_md_en = root_dir / rules['output_markdown_en']
    out_yaml = root_dir / rules['output_yaml']

    if args.check:
        current_md = out_md.read_text(encoding='utf-8') if out_md.exists() else ''
        current_md_en = out_md_en.read_text(encoding='utf-8') if out_md_en.exists() else ''
        current_yaml = out_yaml.read_text(encoding='utf-8') if out_yaml.exists() else ''
        current_tree = load_existing_tree(out_yaml)
        if current_md != md or current_md_en != md_en or current_yaml != yaml_content:
            print('documentation tree sync check: FAIL')
            print(' - generated documentation tree is out of date')
            report_tree_drift(current_tree, tree)
            return 1

        changed = git_changed_files(root_dir)
        root_influence = (set(rules.get('root_influence', [])) | read_root_tree_dependencies(root_dir)) - set(rules.get('excluded_from_graph', []))
        if changed & root_influence and rules['root'] not in changed:
            print('documentation tree sync check: FAIL')
            print(' - root-influence documents changed without README.md update:')
            for path in sorted(changed & root_influence):
                deps = format_dependency_targets(path, node_map(tree))
                print(f'   * {path} -> проверить зависимости: {deps}')
            return 1

        print('documentation tree sync check: OK')
        return 0

    write_if_changed(out_md, md)
    write_if_changed(out_md_en, md_en)
    write_if_changed(out_yaml, yaml_content)
    print('documentation tree generated')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
