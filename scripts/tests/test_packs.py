import json
import pathlib
import shutil
import sys
import tempfile
import tomllib
import unittest

sys.path.append(str(pathlib.Path(__file__).resolve().parent))
from packs_runtime import PackRuntime

ROOT = pathlib.Path(__file__).resolve().parents[2]
PACK_DIR = ROOT / 'packs' / 'regart'


class PacksFrameworkTests(unittest.TestCase):
    def test_pack_install_bad_signature_fails(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = pathlib.Path(td) / 'regart'
            shutil.copytree(PACK_DIR, tmp)
            (tmp / 'signatures' / 'manifest.sha256').write_text('0' * 64 + '  manifest.yaml\n')
            rt = PackRuntime()
            result = rt.install_pack_from_dir(tmp, catalog={'base-observability': ['1.0.0']})
            self.assertFalse(result.ok)
            self.assertFalse(result.activated)
            self.assertEqual(result.gap_event['kind'], 'observability_gap.pack_install_failed')
            self.assertEqual(result.gap_event['details']['fail_stage'], 'signature')

    def test_pack_deps_resolution(self):
        rt = PackRuntime()
        ok, stage, err = rt.resolve_dependencies(
            [
                {'name': 'dep1', 'version_range': '>=1.0.0,<2.0.0'},
                {'name': 'dep2', 'version_range': '>=1.0.0,<2.0.0', 'requires': ['dep1']},
            ],
            {'dep1': ['1.0.0', '1.5.0'], 'dep2': ['1.1.0']},
        )
        self.assertTrue(ok)
        self.assertEqual(stage, '')
        self.assertEqual(rt.installed['dep1'], '1.5.0')

        rt2 = PackRuntime()
        fail_missing = rt2.resolve_dependencies(
            [{'name': 'dep_missing', 'version_range': '>=1.0.0'}],
            {},
        )
        self.assertFalse(fail_missing[0])
        self.assertEqual(fail_missing[1], 'deps')

        rt3 = PackRuntime()
        fail_cycle = rt3.resolve_dependencies(
            [
                {'name': 'a', 'version_range': '>=1.0.0', 'requires': ['b']},
                {'name': 'b', 'version_range': '>=1.0.0', 'requires': ['a']},
            ],
            {'a': ['1.0.0'], 'b': ['1.0.0']},
        )
        self.assertFalse(fail_cycle[0])
        self.assertEqual(fail_cycle[2], 'dependency_cycle')

    def test_pack_install_success(self):
        rt = PackRuntime()
        result = rt.install_pack_from_dir(PACK_DIR, catalog={'base-observability': ['1.0.0', '1.2.0']})
        self.assertTrue(result.ok)
        self.assertTrue(result.activated)

    def test_pack_install_failed_generates_gap_event(self):
        rt = PackRuntime()
        result = rt.install_pack_from_dir(PACK_DIR, catalog={})
        self.assertFalse(result.ok)
        self.assertEqual(result.gap_event['kind'], 'observability_gap.pack_install_failed')
        self.assertEqual(result.gap_event['details']['fail_stage'], 'deps')


class PackRegartTests(unittest.TestCase):
    def test_fixtures_exist_and_have_correlation(self):
        fixtures = ROOT / 'packs' / 'regart' / 'fixtures'
        required = [
            'ui_proxy_unavailable.json',
            'upstream_error.json',
            'ui.graph.empty.json',
            'network_error.json',
            'tools_event.json',
            'models_event.json',
            'graph_event.json',
        ]
        for name in required:
            path = fixtures / name
            self.assertTrue(path.exists(), name)
            data = json.loads(path.read_text())
            for k in ('run_id', 'trace_id', 'span_id', 'source_id', 'source_seq'):
                self.assertIn(k, data)

    def test_pack_regart_examples_validate(self):
        toml_path = ROOT / 'packs' / 'regart' / 'examples' / 'receivers.toml'
        self.assertTrue(toml_path.exists())
        cfg = tomllib.loads(toml_path.read_text())
        kinds = [item['kind'] for item in cfg['receivers']]
        self.assertIn('journald', kinds)
        self.assertIn('file_tail', kinds)
        self.assertIn('stdout_stderr', kinds)
        self.assertIn('net_probe', kinds)

    def test_pack_incompatible_generates_gap(self):
        rt = PackRuntime()
        result = rt.install_pack_from_dir(
            PACK_DIR,
            catalog={'base-observability': ['1.0.0']},
            core_version='9.0.0',
        )
        self.assertFalse(result.ok)
        self.assertEqual(result.gap_event['kind'], 'observability_gap.pack_incompatible')


if __name__ == '__main__':
    unittest.main()
