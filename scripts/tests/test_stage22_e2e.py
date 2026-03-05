import os
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class Stage22Tests(unittest.TestCase):
    def run_cargo_test(self, package: str, test_name: str):
        cmd = [
            "cargo",
            "test",
            "-p",
            package,
            test_name,
            "--",
            "--exact",
            "--nocapture",
        ]
        env = os.environ.copy()
        env.setdefault("RUST_BACKTRACE", "1")
        result = subprocess.run(
            cmd,
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        output = f"{result.stdout}\n{result.stderr}"
        self.assertEqual(
            result.returncode,
            0,
            msg=f"Команда завершилась с ошибкой: {' '.join(cmd)}\n{output}",
        )
        self.assertIn(
            "test result: ok",
            output,
            msg=f"Не найден признак успешного теста в выводе:\n{output}",
        )

    def test_gap_event_has_required_evidence(self):
        self.run_cargo_test(
            "art-core", "e2e_environment_failed_gap_emits_incident_with_evidence"
        )

    def test_power_loss_recovery_contract(self):
        self.run_cargo_test(
            "art-agent", "spool_corruption_recovery_creates_new_spool_and_gap"
        )

    def test_ack_is_monotonic_after_recovery(self):
        self.run_cargo_test(
            "art-core", "ingest_ack_upto_seq_is_monotonic_after_error_recovery"
        )


if __name__ == "__main__":
    unittest.main()
