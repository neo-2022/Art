import hashlib
import json
import pathlib
import subprocess
import tempfile
import unittest


class ExportAuditPackTests(unittest.TestCase):
    def test_export_creates_all_files_and_valid_checksums(self):
        with tempfile.TemporaryDirectory() as td:
            out = pathlib.Path(td)
            subprocess.run([
                "bash", "scripts/export_audit_pack.sh",
                "--from", "2026-03-01T00:00:00Z",
                "--to", "2026-03-02T00:00:00Z",
                "--out_dir", str(out)
            ], check=True)
            files = ["incidents.json", "incidents.csv", "audit.json", "audit.csv", "meta.json", "checksums.txt"]
            for name in files:
                self.assertTrue((out / name).exists(), name)

            meta = json.loads((out / "meta.json").read_text())
            for key in ("build_id", "effective_profile_id", "export_window", "generated_at"):
                self.assertIn(key, meta)

            sums = {}
            for line in (out / "checksums.txt").read_text().splitlines():
                digest, name = line.split("  ", 1)
                sums[name] = digest
            for name in ["incidents.json", "incidents.csv", "audit.json", "audit.csv", "meta.json"]:
                digest = hashlib.sha256((out / name).read_bytes()).hexdigest()
                self.assertEqual(sums.get(name), digest)


if __name__ == "__main__":
    unittest.main()
