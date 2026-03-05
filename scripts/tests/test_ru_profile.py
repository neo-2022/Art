import os
import pathlib
import signal
import subprocess
import tempfile
import time
import unittest
import urllib.request


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
            port = "18131"
            core = subprocess.Popen(
                ["cargo", "run", "-p", "art-core"],
                cwd=pathlib.Path(__file__).resolve().parents[2],
                env={**os.environ, "CORE_PORT": port},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                deadline = time.time() + 20
                while time.time() < deadline:
                    try:
                        with urllib.request.urlopen(
                            f"http://127.0.0.1:{port}/metrics", timeout=1
                        ):
                            break
                    except Exception:
                        time.sleep(0.2)
                else:
                    self.fail("core not ready")

                ingest_req = urllib.request.Request(
                    f"http://127.0.0.1:{port}/api/v1/ingest",
                    data='{"events":[{"kind":"ru.export.seed","severity":"info","source_id":"ru:test","source_seq":1}]}'.encode("utf-8"),
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urllib.request.urlopen(ingest_req, timeout=10) as resp:
                    self.assertEqual(resp.status, 200)

                env = os.environ.copy()
                env["EFFECTIVE_PROFILE_ID"] = "global"
                env["CORE_BASE_URL"] = f"http://127.0.0.1:{port}"
                p = subprocess.run([
                    "bash", "scripts/export_audit_pack.sh",
                    "--from", "2026-03-01T00:00:00Z",
                    "--to", "2026-03-02T00:00:00Z",
                    "--out_dir", td,
                ], env=env, capture_output=True, text=True)
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertTrue((pathlib.Path(td) / "checksums.txt").exists())
            finally:
                if core.poll() is None:
                    core.send_signal(signal.SIGTERM)
                    try:
                        core.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        core.kill()
                        core.wait(timeout=5)

    def test_export_blocked_by_server_ru_profile(self):
        with tempfile.TemporaryDirectory() as td:
            config_path = pathlib.Path(td) / "core_ru.toml"
            config_path.write_text(
                "\n".join(
                    [
                        'profile_id = "ru"',
                        "retention_days = 30",
                        'export_mode = "restricted"',
                        'egress_policy = "strict"',
                        'residency = "ru-only"',
                        'updates_mode = "controlled"',
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            port = "18132"
            core = subprocess.Popen(
                ["cargo", "run", "-p", "art-core"],
                cwd=pathlib.Path(__file__).resolve().parents[2],
                env={**os.environ, "CORE_PORT": port, "CORE_CONFIG_PATH": str(config_path)},
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                deadline = time.time() + 20
                while time.time() < deadline:
                    try:
                        with urllib.request.urlopen(
                            f"http://127.0.0.1:{port}/metrics", timeout=1
                        ):
                            break
                    except Exception:
                        time.sleep(0.2)
                else:
                    self.fail("core ru profile not ready")

                env = os.environ.copy()
                env["CORE_BASE_URL"] = f"http://127.0.0.1:{port}"
                env["EFFECTIVE_PROFILE_ID"] = "global"
                proc = subprocess.run(
                    [
                        "bash",
                        "scripts/export_audit_pack.sh",
                        "--from",
                        "2026-03-01T00:00:00Z",
                        "--to",
                        "2026-03-02T00:00:00Z",
                        "--out_dir",
                        td,
                    ],
                    env=env,
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(proc.returncode, 0)
                self.assertIn("observability_gap.cross_border_export_blocked", proc.stderr)
            finally:
                if core.poll() is None:
                    core.send_signal(signal.SIGTERM)
                    try:
                        core.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        core.kill()
                        core.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
