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
    node_type: str
    lines: int
    root_influence: bool
    children: List[str] = field(default_factory=list)
    incoming: List[str] = field(default_factory=list)
    files_count: int = 0
    index_target: str | None = None
    missing_index: bool = False


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


def file_line_count(path: Path) -> int:
    with path.open('r', encoding='utf-8') as handle:
        return sum(1 for _ in handle)


def rel_to_root(path: Path, root_dir: Path) -> str | None:
    try:
        return path.resolve().relative_to(root_dir.resolve()).as_posix()
    except ValueError:
        return None


def resolve_link_target(base_file: Path, link: str, root_dir: Path, allowed_exts: Set[str], excluded: Set[str]) -> Tuple[str, str | None]:
    if not link or link.startswith('#') or '://' in link:
        return 'ignored', None
    clean = link.split('#', 1)[0].split('?', 1)[0].strip()
    if not clean:
        return 'ignored', None
    target = (base_file.parent / clean).resolve()
    rel_str = rel_to_root(target, root_dir)
    if rel_str is None:
        return 'ignored', None
    if rel_str in excluded:
        return 'excluded', rel_str
    if target.exists() and target.is_dir():
        return 'dir', rel_str
    if target.suffix.lower() not in allowed_exts:
        return 'ignored', None
    if not target.exists():
        return 'missing', rel_str
    return 'file', rel_str


def ensure_document_node(nodes: Dict[str, Node], rel_path: str, root_dir: Path, root_influence: Set[str]) -> Node:
    existing = nodes.get(rel_path)
    if existing:
        return existing
    path = root_dir / rel_path
    node = Node(
        path=rel_path,
        node_type='document',
        lines=file_line_count(path),
        root_influence=rel_path in root_influence,
        files_count=1,
        index_target=rel_path,
    )
    nodes[rel_path] = node
    return node


def collection_index_target(dir_path: Path, dir_rel: str, root_dir: Path, allowed_exts: Set[str], excluded: Set[str], index_names: List[str]) -> str | None:
    for name in index_names:
        candidate = dir_path / name
        if not candidate.exists() or not candidate.is_file():
            continue
        candidate_rel = rel_to_root(candidate, root_dir)
        if candidate_rel is None or candidate_rel in excluded:
            continue
        if candidate.suffix.lower() not in allowed_exts:
            continue
        return candidate_rel
    return None


def collection_stats(dir_path: Path, root_dir: Path, allowed_exts: Set[str], excluded: Set[str]) -> Tuple[int, int]:
    files_count = 0
    lines = 0
    for candidate in sorted(dir_path.rglob('*')):
        if not candidate.is_file():
            continue
        rel = rel_to_root(candidate, root_dir)
        if rel is None or rel in excluded:
            continue
        if candidate.suffix.lower() not in allowed_exts:
            continue
        files_count += 1
        lines += file_line_count(candidate)
    return files_count, lines


def ensure_collection_node(
    nodes: Dict[str, Node],
    dir_rel: str,
    root_dir: Path,
    root_influence: Set[str],
    allowed_exts: Set[str],
    excluded: Set[str],
    index_names: List[str],
) -> Node:
    existing = nodes.get(dir_rel)
    if existing:
        return existing
    dir_path = root_dir / dir_rel
    files_count, lines = collection_stats(dir_path, root_dir, allowed_exts, excluded)
    index_target = collection_index_target(dir_path, dir_rel, root_dir, allowed_exts, excluded, index_names)
    root_flag = dir_rel in root_influence or (index_target in root_influence if index_target else False)
    node = Node(
        path=dir_rel,
        node_type='collection',
        lines=lines,
        root_influence=root_flag,
        files_count=files_count,
        index_target=index_target,
        missing_index=index_target is None,
        children=[index_target] if index_target else [],
    )
    nodes[dir_rel] = node
    return node


def build_tree(root_dir: Path, rules: dict) -> Tuple[dict, str]:
    root_file = rules['root']
    allowed_exts = set(rules.get('allowed_extensions', []))
    excluded = set(rules.get('excluded_from_graph', []))
    index_names = rules.get('collection_index_candidates', ['README.md', 'index.md'])
    root_influence = (set(rules.get('root_influence', [])) | read_root_tree_dependencies(root_dir)) - excluded

    queue = deque([root_file])
    seen: Set[str] = set()
    nodes: Dict[str, Node] = {}
    missing_targets: Dict[str, List[str]] = {}
    total_links = 0

    while queue:
        rel_path = queue.popleft()
        if rel_path in seen:
            continue
        seen.add(rel_path)
        path = root_dir / rel_path
        if not path.exists() or not path.is_file():
            continue
        node = ensure_document_node(nodes, rel_path, root_dir, root_influence)

        if path.suffix.lower() != '.md':
            continue

        text = path.read_text(encoding='utf-8')
        for raw_link in RE_LINK.findall(text):
            total_links += 1
            kind, target_rel = resolve_link_target(path, raw_link, root_dir, allowed_exts, excluded)
            if kind in {'ignored', 'excluded'} or not target_rel:
                continue
            if kind == 'missing':
                missing_targets.setdefault(rel_path, []).append(target_rel)
                continue
            if kind == 'dir':
                child = ensure_collection_node(nodes, target_rel, root_dir, root_influence, allowed_exts, excluded, index_names)
                if target_rel not in node.children:
                    node.children.append(target_rel)
                if rel_path not in child.incoming:
                    child.incoming.append(rel_path)
                if child.index_target:
                    queue.append(child.index_target)
                continue
            if kind == 'file':
                target = root_dir / target_rel
                if not target.exists():
                    missing_targets.setdefault(rel_path, []).append(target_rel)
                    continue
                child = ensure_document_node(nodes, target_rel, root_dir, root_influence)
                if target_rel not in node.children:
                    node.children.append(target_rel)
                if rel_path not in child.incoming:
                    child.incoming.append(rel_path)
                queue.append(target_rel)

    root_children = nodes[root_file].children if root_file in nodes else []
    total_edges_in_tree = sum(len(node.children) for node in nodes.values())
    document_nodes = [node for node in nodes.values() if node.node_type == 'document']
    collection_nodes = [node for node in nodes.values() if node.node_type == 'collection']
    total_lines_in_tree = sum(node.lines for node in document_nodes)
    total_collection_lines = sum(node.lines for node in collection_nodes)
    collections_without_index = sorted(node.path for node in collection_nodes if node.missing_index)
    tree = {
        'version': '1.1',
        'status': 'ACTIVE',
        'root': root_file,
        'total_documents': len(document_nodes),
        'total_collection_nodes': len(collection_nodes),
        'total_markdown_links_scanned': total_links,
        'total_tree_edges': total_edges_in_tree,
        'total_file_links_in_tree': total_edges_in_tree,
        'total_lines_in_tree': total_lines_in_tree,
        'total_lines_in_collections': total_collection_lines,
        'root_direct_children': len(root_children),
        'root_influence_documents': sorted(root_influence),
        'excluded_from_graph': sorted(excluded),
        'collections_without_index': collections_without_index,
        'nodes': [
            {
                'path': n.path,
                'node_type': n.node_type,
                'lines': n.lines,
                'files_count': n.files_count,
                'root_influence': n.root_influence,
                'children': n.children,
                'incoming': n.incoming,
                'index_target': n.index_target,
                'missing_index': n.missing_index,
            }
            for n in sorted(nodes.values(), key=lambda item: item.path)
        ],
        'missing_targets': missing_targets,
    }

    mermaid_lines = ['graph TD']
    ids: Dict[str, str] = {}
    for idx, path in enumerate(sorted(nodes.keys()), start=1):
        ids[path] = f'N{idx}'
    for path, node in sorted(nodes.items()):
        if node.node_type == 'collection':
            label = f"{path}/\\nкаталог: {node.files_count} файлов\\n{node.lines} строк"
            if node.missing_index:
                label += '\\nINDEX-MISSING'
        else:
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


def render_node_line(node: dict, output_rel: str, prefix: str) -> str:
    marker = ' `ROOT-INFLUENCE`' if node['root_influence'] else ''
    if node['node_type'] == 'collection':
        label = f"`каталог`, файлов `{node['files_count']}`, строк `{node['lines']}`"
        if node.get('missing_index'):
            return f"{prefix}- `{node['path']}/` — {label}{marker} `INDEX-MISSING`"
        return f"{prefix}- [`{node['path']}/`]({rel_link(output_rel, node['index_target'])}) — {label}{marker}"
    return f"{prefix}- [`{node['path']}`]({rel_link(output_rel, node['path'])}) — `{node['lines']}` строк{marker}"


def build_tree_lines(root: str, nodes_by_path: Dict[str, dict], output_rel: str, prefix: str = '', visited: Set[str] | None = None) -> List[str]:
    if visited is None:
        visited = set()
    node = nodes_by_path[root]
    line = render_node_line(node, output_rel, prefix)
    lines = [line]
    if root in visited:
        lines[-1] += ' `REUSED-LINK`'
        return lines
    visited.add(root)
    for child in node['children']:
        lines.extend(build_tree_lines(child, nodes_by_path, output_rel, prefix + '  ', visited.copy()))
    return lines


def render_markdown(tree: dict, mermaid: str, output_rel: str, lang: str = 'ru') -> str:
    nodes_by_path = {node['path']: node for node in tree['nodes']}
    root = tree['root']
    root_node = nodes_by_path[root]
    tree_lines = build_tree_lines(root, nodes_by_path, output_rel)
    missing = tree.get('missing_targets', {})
    excluded = tree.get('excluded_from_graph', [])
    root_influence_lines = []
    for path in tree['root_influence_documents']:
        node = nodes_by_path.get(path)
        if node:
            if node['node_type'] == 'collection':
                if node.get('missing_index'):
                    root_influence_lines.append(f"- `{path}/` — `каталог`, файлов `{node['files_count']}`, строк `{node['lines']}`, `INDEX-MISSING`")
                else:
                    root_influence_lines.append(f"- [`{path}/`]({rel_link(output_rel, node['index_target'])}) — `каталог`, файлов `{node['files_count']}`, строк `{node['lines']}`")
            else:
                root_influence_lines.append(f"- [`{path}`]({rel_link(output_rel, path)}) — `{node['lines']}` строк")
        else:
            root_influence_lines.append(f"- `{path}` — `НЕ ПОПАЛ В ДЕРЕВО`")

    missing_lines = ['- нет'] if not missing else [f"- `{src}` -> `{target}`" for src, targets in sorted(missing.items()) for target in targets]
    collection_lines = ['- нет']
    if tree.get('total_collection_nodes'):
        collection_lines = []
        for node in tree['nodes']:
            if node['node_type'] != 'collection':
                continue
            if node.get('missing_index'):
                collection_lines.append(f"- `{node['path']}/` — файлов `{node['files_count']}`, строк `{node['lines']}`, `INDEX-MISSING`")
            else:
                collection_lines.append(f"- [`{node['path']}/`]({rel_link(output_rel, node['index_target'])}) — файлов `{node['files_count']}`, строк `{node['lines']}`")

    missing_index_lines = ['- нет'] if not tree.get('collections_without_index') else [f"- `{path}/`" for path in tree['collections_without_index']]

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
- какие каталоговые узлы входят в дерево как самостоятельные сущности;
- какие документы прямо влияют на корневой `README.md`;
- где возможен drift, который требует обновить корневой `README.md`.

## Что даёт этот слой
- быстрый вход в документацию без потери контекста;
- защиту от неучтённых изменений в ключевых документах;
- наглядную карту зависимостей;
- контроль того, что изменения смыслообразующих документов не проходят мимо корневого `README.md`;
- отдельный контроль каталоговых узлов, которые раньше могли выпадать из дерева.

## Сводка
- Корень дерева: [`{rel_link(output_rel, root)}`]({rel_link(output_rel, root)})
- Строк в корневом `README.md`: `{root_node['lines']}`
- Уникальных документов в дереве: `{tree['total_documents']}`
- Каталоговых узлов в дереве: `{tree['total_collection_nodes']}`
- Общих строк по документным узлам: `{tree['total_lines_in_tree']}`
- Суммарных строк внутри каталоговых узлов: `{tree['total_lines_in_collections']}`
- Всех связей в дереве: `{tree['total_tree_edges']}`
- Просканированных markdown-ссылок: `{tree['total_markdown_links_scanned']}`
- Прямых дочерних ссылок у корня: `{tree['root_direct_children']}`
- Документов с признаком `ROOT-INFLUENCE`: `{len(tree['root_influence_documents'])}`
- Каталоговых узлов без индексного документа: `{len(tree['collections_without_index'])}`

## Граф
```mermaid
{mermaid}
```

## Дерево ссылок
{"\n".join(tree_lines)}

## Документы, влияющие на корневой README
Если изменяется любой документ из этого списка, а `README.md` не изменён, CI подаёт сигнал о рассинхроне.

{"\n".join(root_influence_lines)}

## Каталоговые узлы
Это специальные узлы дерева для ссылок на каталоги. Они считаются автоматически и показывают:
- сколько файлов внутри;
- сколько строк внутри;
- есть ли индексный документ, на который можно безопасно сослаться.

{"\n".join(collection_lines)}

## Каталоговые узлы без индексного документа
Если здесь появляется запись, дерево считается дефектным: каталог есть в ссылках, но не имеет реального индексного документа.

{"\n".join(missing_index_lines)}

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
    current_total_lines = current_tree.get('total_lines_in_tree', sum(node.get('lines', 0) for node in current_nodes.values() if node.get('node_type') == 'document'))
    new_total_lines = new_tree.get('total_lines_in_tree', sum(node.get('lines', 0) for node in new_nodes.values() if node.get('node_type') == 'document'))
    current_collection_lines = current_tree.get('total_lines_in_collections', sum(node.get('lines', 0) for node in current_nodes.values() if node.get('node_type') == 'collection'))
    new_collection_lines = new_tree.get('total_lines_in_collections', sum(node.get('lines', 0) for node in new_nodes.values() if node.get('node_type') == 'collection'))
    print(f' - total_lines_in_tree: {current_total_lines} -> {new_total_lines}')
    print(f' - total_lines_in_collections: {current_collection_lines} -> {new_collection_lines}')

    changed_paths = []
    for path in sorted(set(current_nodes) | set(new_nodes)):
        old_lines = current_nodes.get(path, {}).get('lines')
        new_lines = new_nodes.get(path, {}).get('lines')
        if old_lines != new_lines:
            changed_paths.append((path, old_lines, new_lines, new_nodes.get(path, {}).get('node_type', current_nodes.get(path, {}).get('node_type', 'unknown'))))

    if not changed_paths:
        print(' - line counts changed indirectly (структура дерева или root-influence набор)')
        return

    print(' - changed node line counts:')
    for path, old_lines, new_lines, node_type in changed_paths[:25]:
        deps = format_dependency_targets(path, new_nodes)
        print(f'   * {path} [{node_type}]: {old_lines} -> {new_lines}; зависит от/влияет через: {deps}')
    if len(changed_paths) > 25:
        print(f'   ... ещё {len(changed_paths) - 25} узлов')


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

        if tree.get('collections_without_index'):
            print('documentation tree sync check: FAIL')
            print(' - collection nodes without index document:')
            for path in tree['collections_without_index']:
                print(f'   * {path}/ -> создать README.md или index.md')
            return 1

        if tree.get('missing_targets'):
            print('documentation tree sync check: FAIL')
            print(' - tree contains broken file links:')
            for src, targets in sorted(tree['missing_targets'].items()):
                for target in targets:
                    print(f'   * {src} -> {target}')
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
