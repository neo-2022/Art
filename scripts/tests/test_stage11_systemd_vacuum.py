#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shlex
import sqlite3
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SERVICE_PATH = ROOT / "systemd" / "art-vacuum.service"
TIMER_PATH = ROOT / "systemd" / "art-vacuum.timer"


def service_execstart() -> str:
    for line in SERVICE_PATH.read_text(encoding="utf-8").splitlines():
        if line.startswith("ExecStart="):
            return line.split("=", 1)[1].strip()
    raise AssertionError("ExecStart not found")


def run_service(*, db_path: Path, ingest_flag: Path, schedule: str = "Sunday_03:30") -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["ART_CORE_DB_PATH"] = str(db_path)
    env["ART_INGEST_ACTIVE_FILE"] = str(ingest_flag)
    env["ART_VACUUM_SCHEDULE"] = schedule
    return subprocess.run(
        shlex.split(service_execstart()),
        text=True,
        capture_output=True,
        env=env,
        cwd=ROOT,
    )


class Stage11SystemdVacuumTests(unittest.TestCase):
    def test_systemd_unit_and_timer_verify(self) -> None:
        proc = subprocess.run(
            ["systemd-analyze", "verify", str(SERVICE_PATH), str(TIMER_PATH)],
            text=True,
            capture_output=True,
            cwd=ROOT,
        )
        self.assertEqual(proc.returncode, 0, msg=proc.stderr or proc.stdout)

    def test_vacuum_service_smoke_success(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            ingest_flag = Path(tmp) / "ingest_active.flag"
            conn = sqlite3.connect(str(db_path))
            conn.execute("PRAGMA journal_mode=WAL;")
            conn.execute("CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY, payload TEXT NOT NULL);")
            conn.execute("INSERT INTO events(payload) VALUES ('x');")
            conn.commit()
            conn.close()

            proc = run_service(db_path=db_path, ingest_flag=ingest_flag)
            self.assertEqual(proc.returncode, 0, msg=proc.stderr)
            self.assertIn("vacuum_status=ok", proc.stdout)

            conn = sqlite3.connect(str(db_path))
            row = conn.execute("PRAGMA integrity_check;").fetchone()
            conn.close()
            self.assertEqual(row[0], "ok")

    def test_vacuum_service_skips_when_ingest_active(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            ingest_flag = Path(tmp) / "ingest_active.flag"
            conn = sqlite3.connect(str(db_path))
            conn.execute("CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY, payload TEXT NOT NULL);")
            conn.execute("INSERT INTO events(payload) VALUES ('x');")
            conn.commit()
            conn.close()
            ingest_flag.write_text("1", encoding="utf-8")

            proc = run_service(db_path=db_path, ingest_flag=ingest_flag)
            self.assertEqual(
                proc.returncode,
                0,
                msg=f"stdout={proc.stdout!r} stderr={proc.stderr!r}",
            )
            self.assertIn("vacuum_status=skipped", proc.stdout)

    def test_vacuum_service_emits_gap_event_on_missing_db(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "missing" / "core.sqlite3"
            ingest_flag = Path(tmp) / "ingest_active.flag"

            proc = run_service(db_path=db_path, ingest_flag=ingest_flag)
            self.assertNotEqual(proc.returncode, 0)
            payload = json.loads(proc.stderr.strip())
            self.assertEqual(payload["kind"], "observability_gap.storage_vacuum_failed")
            self.assertEqual(payload["where"], "core/storage")
            self.assertEqual(payload["why"], "missing_db_file")
            self.assertEqual(payload["evidence"]["db_path"], str(db_path))
            self.assertEqual(payload["evidence"]["schedule"], "Sunday_03:30")
            self.assertTrue(payload["evidence"]["trace_id"])


if __name__ == "__main__":
    unittest.main()
