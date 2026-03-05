import os
import pathlib
import subprocess
import tempfile
import unittest


class RuProfileTests(unittest.TestCase):
    def test_export_blocked_for_ru_profile(self):
        with tempfile.TemporaryDirectory() as td:
            env = os.environ.copy()
            env["EFFECTIVE_PROFILE_ID"] = "ru"
            p = subprocess.run([
                "bash", "scripts/export_audit_pack.sh",
                "--from", "2026-03-01T00:00:00Z",
                "--to", "2026-03-02T00:00:00Z",
                "--out_dir", td,
            ], env=env, capture_output=True, text=True)
            self.assertNotEqual(p.returncode, 0)
            self.assertIn("observability_gap.cross_border_export_blocked", p.stderr)

    def test_export_allowed_for_non_ru_profile(self):
        with tempfile.TemporaryDirectory() as td:
            env = os.environ.copy()
            env["EFFECTIVE_PROFILE_ID"] = "global"
            p = subprocess.run([
                "bash", "scripts/export_audit_pack.sh",
                "--from", "2026-03-01T00:00:00Z",
                "--to", "2026-03-02T00:00:00Z",
                "--out_dir", td,
            ], env=env, capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertTrue((pathlib.Path(td) / "checksums.txt").exists())


if __name__ == "__main__":
    unittest.main()
