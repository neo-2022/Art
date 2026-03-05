import pathlib
import subprocess
import tempfile
import unittest


class ExportAuditPackTests(unittest.TestCase):
    def test_export_creates_all_files(self):
        with tempfile.TemporaryDirectory() as td:
            out = pathlib.Path(td)
            subprocess.run([
                "bash", "scripts/export_audit_pack.sh",
                "--from", "2026-03-01T00:00:00Z",
                "--to", "2026-03-02T00:00:00Z",
                "--out_dir", str(out)
            ], check=True)
            for name in ["incidents.json", "incidents.csv", "audit.json", "audit.csv", "meta.json", "checksums.txt"]:
                self.assertTrue((out / name).exists(), name)


if __name__ == "__main__":
    unittest.main()
