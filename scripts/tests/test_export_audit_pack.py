import hashlib
import json
import os
import pathlib
import signal
import subprocess
import tempfile
import time
import unittest
import urllib.request


def wait_core_ready(port: int, timeout: float = 180.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/metrics", timeout=1):
                return
        except Exception:
            time.sleep(0.2)
    raise AssertionError("core is not ready")


class ExportAuditPackTests(unittest.TestCase):
    CORE_PORT = 18130

    def setUp(self) -> None:
        env = os.environ.copy()
        env["CORE_PORT"] = str(self.CORE_PORT)
        self.core = subprocess.Popen(
            ["cargo", "run", "-p", "art-core"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            cwd=pathlib.Path(__file__).resolve().parents[2],
            env=env,
        )
        wait_core_ready(self.CORE_PORT)

    def tearDown(self) -> None:
        if self.core.poll() is None:
            self.core.send_signal(signal.SIGTERM)
            try:
                self.core.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.core.kill()
                self.core.wait(timeout=5)

    def _seed_runtime_data(self) -> None:
        base = f"http://127.0.0.1:{self.CORE_PORT}"
        payload = {
            "events": [
                {
                    "kind": "compliance.export.seed",
                    "severity": "info",
                    "run_id": "export-seed-run",
                    "trace_id": "export-seed-trace",
                    "span_id": "export-seed-span",
                    "source_id": "export:seed",
                    "source_seq": 1,
                }
            ]
        }
        ingest_req = urllib.request.Request(
            f"{base}/api/v1/ingest",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(ingest_req, timeout=10) as resp:
            self.assertEqual(resp.status, 200)

        action_req = urllib.request.Request(
            f"{base}/api/v1/actions/execute",
            data=json.dumps({"action": "service.status", "target": "core"}).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-actor-role": "admin",
                "x-action-preflight-id": "pf-export-seed-1",
            },
            method="POST",
        )
        with urllib.request.urlopen(action_req, timeout=10) as resp:
            self.assertEqual(resp.status, 200)

    def test_export_creates_all_files_and_valid_checksums(self) -> None:
        self._seed_runtime_data()
        with tempfile.TemporaryDirectory() as td:
            out = pathlib.Path(td)
            env = os.environ.copy()
            env["CORE_BASE_URL"] = f"http://127.0.0.1:{self.CORE_PORT}"
            subprocess.run(
                [
                    "bash",
                    "scripts/export_audit_pack.sh",
                    "--from",
                    "1970-01-01T00:00:00Z",
                    "--to",
                    "2100-01-01T00:00:00Z",
                    "--out_dir",
                    str(out),
                ],
                cwd=pathlib.Path(__file__).resolve().parents[2],
                env=env,
                check=True,
            )
            files = [
                "incidents.json",
                "incidents.csv",
                "audit.json",
                "audit.csv",
                "meta.json",
                "checksums.txt",
            ]
            for name in files:
                self.assertTrue((out / name).exists(), name)

            meta = json.loads((out / "meta.json").read_text(encoding="utf-8"))
            for key in ("build_id", "effective_profile_id", "export_window", "generated_at"):
                self.assertIn(key, meta)
            self.assertEqual(meta["effective_profile_id"], "global")

            incidents = json.loads((out / "incidents.json").read_text(encoding="utf-8"))
            self.assertTrue(
                any(item.get("run_id") == "export-seed-run" for item in incidents),
                incidents,
            )
            audits = json.loads((out / "audit.json").read_text(encoding="utf-8"))
            self.assertTrue(any(item.get("action") == "service.status" for item in audits), audits)

            inc_csv_head = (out / "incidents.csv").read_text(encoding="utf-8").splitlines()[0]
            aud_csv_head = (out / "audit.csv").read_text(encoding="utf-8").splitlines()[0]
            self.assertEqual(
                inc_csv_head,
                "id,status,kind,severity,action_ref,run_id,trace_id,span_id",
            )
            self.assertEqual(
                aud_csv_head,
                "id,timestamp,actor_id,actor_role,mcp_mode,action,target,result,trace_id,evidence_ref,client_ip,user_agent,prev_hash,entry_hash",
            )

            sums = {}
            for line in (out / "checksums.txt").read_text(encoding="utf-8").splitlines():
                digest, name = line.split("  ", 1)
                sums[name] = digest
            for name in ["incidents.json", "incidents.csv", "audit.json", "audit.csv", "meta.json"]:
                digest = hashlib.sha256((out / name).read_bytes()).hexdigest()
                self.assertEqual(sums.get(name), digest)

    def test_invalid_window_returns_export_failed(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            env = os.environ.copy()
            env["CORE_BASE_URL"] = f"http://127.0.0.1:{self.CORE_PORT}"
            proc = subprocess.run(
                [
                    "bash",
                    "scripts/export_audit_pack.sh",
                    "--from",
                    "2100-01-01T00:00:00Z",
                    "--to",
                    "1970-01-01T00:00:00Z",
                    "--out_dir",
                    td,
                ],
                cwd=pathlib.Path(__file__).resolve().parents[2],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(proc.returncode, 0)
            self.assertIn("observability_gap.export_failed", proc.stderr)


if __name__ == "__main__":
    unittest.main()
