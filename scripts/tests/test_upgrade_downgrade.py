import json
import os
import signal
import subprocess
import time
import unittest
import urllib.error
import urllib.request


def _wait_ready(port: int, timeout: float = 20.0) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/metrics", timeout=1):
                return
        except Exception:
            time.sleep(0.2)
    raise AssertionError(f"core not ready on port {port}")


class CoreRuntime:
    def __init__(self, port: int) -> None:
        self.port = port
        self.proc: subprocess.Popen | None = None

    def start(self) -> None:
        env = dict(os.environ)
        env["CORE_PORT"] = str(self.port)
        self.proc = subprocess.Popen(
            ["cargo", "run", "-p", "art-core"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            env=env,
        )
        _wait_ready(self.port)

    def stop(self) -> None:
        if self.proc is None:
            return
        if self.proc.poll() is None:
            self.proc.send_signal(signal.SIGTERM)
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait(timeout=5)
        self.proc = None

    def ingest(self, events: list[dict]) -> dict:
        payload = json.dumps({"events": events}).encode("utf-8")
        req = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/api/v1/ingest",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            self._assert_status(resp.status, 200, "ingest")
            return json.loads(resp.read().decode("utf-8"))

    def snapshot(self) -> dict:
        with urllib.request.urlopen(
            f"http://127.0.0.1:{self.port}/api/v1/snapshot", timeout=10
        ) as resp:
            self._assert_status(resp.status, 200, "snapshot")
            return json.loads(resp.read().decode("utf-8"))

    def stream_smoke(self) -> str:
        req = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/api/v1/stream",
            headers={"x-core-stream-hold-seconds": "1"},
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            self._assert_status(resp.status, 200, "stream")
            return resp.read().decode("utf-8")

    @staticmethod
    def _assert_status(got: int, expected: int, where: str) -> None:
        if got != expected:
            raise AssertionError(f"{where}: status={got}, expected={expected}")


def build_events(run_id: str, count: int) -> list[dict]:
    return [
        {
            "kind": "upgrade.regression",
            "severity": "info",
            "run_id": run_id,
            "trace_id": f"{run_id}-trace-{idx}",
            "span_id": f"{run_id}-span-{idx}",
            "source_id": f"upgrade:{run_id}",
            "source_seq": idx,
        }
        for idx in range(1, count + 1)
    ]


class UpgradeDowngradeTests(unittest.TestCase):
    def _roundtrip_phase(self, base_run: str) -> None:
        port = 18100
        n = CoreRuntime(port)
        n.start()
        try:
            source_events = build_events(f"{base_run}-n", 100)
            ingest_n = n.ingest(source_events)
            self.assertEqual(ingest_n["accepted"], 100)
            self.assertEqual(ingest_n["invalid"], 0)
            ack_n = ingest_n["ack"]["upto_seq"]
            snap_n = n.snapshot()
            incidents_n = snap_n.get("incidents", [])
            self.assertGreaterEqual(len(incidents_n), 2)
            self.assertTrue(
                any(item.get("run_id") == f"{base_run}-n" for item in incidents_n),
                "incidents must preserve run_id correlation",
            )
        finally:
            n.stop()

        # Simulated migration check: new runtime (N+1 or N-1) replays preserved payload.
        migrated = CoreRuntime(port)
        migrated.start()
        try:
            replay = migrated.ingest(source_events)
            self.assertEqual(replay["accepted"], 100)
            self.assertEqual(replay["invalid"], 0)
            self.assertGreaterEqual(replay["ack"]["upto_seq"], ack_n)

            post = migrated.snapshot()
            incidents_post = post.get("incidents", [])
            self.assertGreaterEqual(len(incidents_post), len(incidents_n))
            self.assertTrue(
                any(item.get("run_id") == f"{base_run}-n" for item in incidents_post),
                "post-migration incidents must preserve run_id correlation",
            )

            stream_payload = migrated.stream_smoke()
            self.assertIn("event: message", stream_payload)
        finally:
            migrated.stop()

    def test_n_to_n_plus_1(self) -> None:
        self._roundtrip_phase("upgrade")

    def test_n_to_n_minus_1(self) -> None:
        self._roundtrip_phase("downgrade")


if __name__ == "__main__":
    unittest.main()
