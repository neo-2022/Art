import os
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


if __name__ == "__main__":
    unittest.main()
