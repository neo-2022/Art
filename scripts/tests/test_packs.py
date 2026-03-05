import json
import pathlib
import sys
import tomllib
import unittest

sys.path.append(str(pathlib.Path(__file__).resolve().parent))
from packs_runtime import PackRuntime

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PacksFrameworkTests(unittest.TestCase):
    def test_pack_install_bad_signature_fails(self):
        rt = PackRuntime()
        result = rt.install_pack(
            {
                "name": "pack-a",
                "version": "1.0.0",
                "signature": "invalid",
                "dependencies": [],
                "catalog": {},
            }
        )
        self.assertFalse(result.ok)
        self.assertFalse(result.activated)
        self.assertEqual(result.gap_event["kind"], "observability_gap.pack_install_failed")
        self.assertEqual(result.gap_event["details"]["fail_stage"], "signature")

    def test_pack_deps_resolution(self):
        rt = PackRuntime()
        ok = rt.install_pack(
            {
                "name": "pack-b",
                "version": "1.0.0",
                "signature": "valid",
                "dependencies": [{"name": "dep1", "version_range": ">=1.0.0,<2.0.0"}],
                "catalog": {"dep1": ["1.0.0", "1.5.0", "2.0.0"]},
            }
        )
        self.assertTrue(ok.ok)
        self.assertEqual(rt.installed["dep1"], "1.5.0")

        fail_missing = rt.install_pack(
            {
                "name": "pack-c",
                "version": "1.0.0",
                "signature": "valid",
                "dependencies": [{"name": "dep_missing", "version_range": ">=1.0.0"}],
                "catalog": {},
            }
        )
        self.assertFalse(fail_missing.ok)
        self.assertEqual(fail_missing.gap_event["details"]["fail_stage"], "deps")

    def test_pack_install_success(self):
        rt = PackRuntime()
        result = rt.install_pack(
            {
                "name": "pack-success",
                "version": "1.2.3",
                "signature": "valid",
                "dependencies": [],
                "catalog": {},
            }
        )
        self.assertTrue(result.ok)
        self.assertTrue(result.activated)

    def test_pack_install_failed_generates_gap_event(self):
        rt = PackRuntime()
        result = rt.install_pack(
            {
                "name": "pack-fail",
                "version": "1.0.0",
                "signature": "valid",
                "dependencies": [{"name": "dep-x", "version_range": ">=9.0.0"}],
                "catalog": {"dep-x": ["1.0.0"]},
            }
        )
        self.assertFalse(result.ok)
        self.assertEqual(result.gap_event["kind"], "observability_gap.pack_install_failed")


class PackRegartTests(unittest.TestCase):
    def test_fixtures_exist_and_have_correlation(self):
        fixtures = ROOT / "packs" / "regart" / "fixtures"
        required = [
            "ui_proxy_unavailable.json",
            "upstream_error.json",
            "ui.graph.empty.json",
            "network_error.json",
            "tools_event.json",
            "models_event.json",
            "graph_event.json",
        ]
        for name in required:
            path = fixtures / name
            self.assertTrue(path.exists(), name)
            data = json.loads(path.read_text())
            for k in ("run_id", "trace_id", "span_id", "source_id", "source_seq"):
                self.assertIn(k, data)

    def test_pack_regart_examples_validate(self):
        toml_path = ROOT / "packs" / "regart" / "examples" / "receivers.toml"
        self.assertTrue(toml_path.exists())
        cfg = tomllib.loads(toml_path.read_text())
        kinds = [item["kind"] for item in cfg["receivers"]]
        self.assertIn("journald", kinds)
        self.assertIn("file_tail", kinds)
        self.assertIn("stdout_stderr", kinds)
        self.assertIn("net_probe", kinds)

    def test_pack_incompatible_generates_gap(self):
        rt = PackRuntime()
        result = rt.install_pack(
            {
                "name": "regart",
                "version": "1.0.0",
                "signature": "valid",
                "core_version_range": ">=2.0.0,<3.0.0",
                "dependencies": [],
                "catalog": {},
            },
            core_version="1.0.0",
        )
        self.assertFalse(result.ok)
        self.assertEqual(result.gap_event["kind"], "observability_gap.pack_incompatible")


if __name__ == "__main__":
    unittest.main()
