import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


GENERATOR_PATH = Path(__file__).resolve().parents[1] / 'ci' / 'generate_documentation_tree.py'
SPEC = importlib.util.spec_from_file_location('documentation_tree_generator', GENERATOR_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class DocumentationTreeCollectionTests(unittest.TestCase):
    def setUp(self):
        self.root_dir = Path(__file__).resolve().parents[2]
        self.rules = MODULE.read_rules(self.root_dir)

    def test_existing_collection_nodes_have_correct_counts(self):
        tree, _ = MODULE.build_tree(self.root_dir, self.rules)
        nodes = {node['path']: node for node in tree['nodes']}
        self.assertEqual(tree['missing_targets'], {})
        expected = {
            'docs/contracts/v2/schemas': 'docs/contracts/v2/schemas/README.md',
            'docs/governance/evidence': 'docs/governance/evidence/README.md',
            'docs/governance/release_decisions': 'docs/governance/release_decisions/README.md',
        }

        for collection_path, index_target in expected.items():
            self.assertIn(collection_path, nodes)
            node = nodes[collection_path]
            self.assertEqual(node['node_type'], 'collection')
            self.assertFalse(node['missing_index'])
            self.assertEqual(node['index_target'], index_target)

            files_count, lines = MODULE.collection_stats(
                self.root_dir / collection_path,
                self.root_dir,
                set(self.rules['allowed_extensions']),
                set(self.rules['excluded_from_graph']),
            )
            self.assertEqual(node['files_count'], files_count)
            self.assertEqual(node['lines'], lines)

    def test_collection_drift_changes_aggregated_line_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'README.md').write_text('[Schemas](docs/contracts/v2/schemas)\n', encoding='utf-8')
            (root / 'docs/contracts/v2/schemas').mkdir(parents=True)
            (root / 'docs/contracts/v2/schemas/README.md').write_text('# Index\n', encoding='utf-8')
            (root / 'docs/contracts/v2/schemas/a.json').write_text('{\n  "a": 1\n}\n', encoding='utf-8')
            rules = {
                'root': 'README.md',
                'allowed_extensions': ['.md', '.json', '.yaml', '.yml'],
                'excluded_from_graph': [],
                'collection_index_candidates': ['README.md', 'index.md'],
                'root_influence': [],
            }
            tree_before, _ = MODULE.build_tree(root, rules)
            before = {node['path']: node for node in tree_before['nodes']}['docs/contracts/v2/schemas']

            (root / 'docs/contracts/v2/schemas/a.json').write_text('{\n  "a": 1,\n  "b": 2\n}\n', encoding='utf-8')
            tree_after, _ = MODULE.build_tree(root, rules)
            after = {node['path']: node for node in tree_after['nodes']}['docs/contracts/v2/schemas']

            self.assertEqual(before['files_count'], after['files_count'])
            self.assertGreater(after['lines'], before['lines'])
            self.assertEqual(after['index_target'], 'docs/contracts/v2/schemas/README.md')

    def test_collection_without_index_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'README.md').write_text('[Artifacts](docs/evidence)\n', encoding='utf-8')
            (root / 'docs/evidence').mkdir(parents=True)
            (root / 'docs/evidence/sample.yaml').write_text('a: 1\n', encoding='utf-8')
            rules = {
                'root': 'README.md',
                'allowed_extensions': ['.md', '.json', '.yaml', '.yml'],
                'excluded_from_graph': [],
                'collection_index_candidates': ['README.md', 'index.md'],
                'root_influence': [],
            }
            tree, _ = MODULE.build_tree(root, rules)
            node = {entry['path']: entry for entry in tree['nodes']}['docs/evidence']
            self.assertEqual(node['node_type'], 'collection')
            self.assertTrue(node['missing_index'])
            self.assertIsNone(node['index_target'])
            self.assertIn('docs/evidence', tree['collections_without_index'])

    def test_missing_file_link_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'README.md').write_text('[Broken](docs/missing.md)\n', encoding='utf-8')
            rules = {
                'root': 'README.md',
                'allowed_extensions': ['.md', '.json', '.yaml', '.yml'],
                'excluded_from_graph': [],
                'collection_index_candidates': ['README.md', 'index.md'],
                'root_influence': [],
            }
            tree, _ = MODULE.build_tree(root, rules)
            self.assertIn('README.md', tree['missing_targets'])
            self.assertIn('docs/missing.md', tree['missing_targets']['README.md'])

    def test_generation_is_deterministic(self):
        tree_a, mermaid_a = MODULE.build_tree(self.root_dir, self.rules)
        tree_b, mermaid_b = MODULE.build_tree(self.root_dir, self.rules)
        self.assertEqual(tree_a, tree_b)
        self.assertEqual(mermaid_a, mermaid_b)


if __name__ == '__main__':
    unittest.main()
