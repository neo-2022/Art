#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.storage_stage11 import (
    chaos_disk_full_smoke,
    chaos_kill9_smoke,
    chaos_wal_corruption_smoke,
    create_backup,
    run_concurrency_test,
    sqlite_integrity_check,
    storage_corruption_recovery,
    vacuum_safe,
)


class StorageStage11Tests(unittest.TestCase):
    def test_concurrency_writers_readers_10000_ops(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            result = run_concurrency_test(db_path=db_path, writers=8, readers=4, total_ops=10000)
            self.assertEqual(result["writers"], 8)
            self.assertEqual(result["readers"], 4)
            self.assertEqual(result["ops_target"], 10000)
            self.assertEqual(result["accepted"], 10000)
            self.assertEqual(result["committed"], result["db_count"])
            self.assertEqual(result["write_errors"], [])
            self.assertEqual(result["read_errors"], [])

    def test_corruption_recovery_restore_success(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            backups = Path(tmp) / "backups"
            run_concurrency_test(db_path=db_path, writers=1, readers=0, total_ops=100)
            backup_id = create_backup(db_path, backups)
            self.assertTrue(backup_id.startswith("core-"))
            status, events = storage_corruption_recovery(
                db_path=db_path,
                backups_dir=backups,
                corruption_type="wal_corruption",
                sqlite_error="malformed",
            )
            self.assertEqual(status.http_status, 503)
            self.assertGreaterEqual(status.retry_after_ms, 0)
            self.assertEqual(events[0]["kind"], "observability_gap.storage_corrupted")
            self.assertTrue(sqlite_integrity_check(db_path))

    def test_corruption_recovery_restore_fail_goes_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            backups = Path(tmp) / "backups"
            run_concurrency_test(db_path=db_path, writers=1, readers=0, total_ops=10)
            create_backup(db_path, backups)

            def force_fail(_db: Path, _backups: Path, _backup_id: str) -> bool:
                return False

            status, events = storage_corruption_recovery(
                db_path=db_path,
                backups_dir=backups,
                corruption_type="wal_corruption",
                sqlite_error="malformed",
                restore_executor=force_fail,
            )
            self.assertEqual(status.http_status, 503)
            self.assertGreaterEqual(status.retry_after_ms, 0)
            self.assertEqual(status.mode, "read_only")
            self.assertTrue(any(e["kind"] == "observability_gap.storage_read_only" for e in events))

    def test_vacuum_safe_runs_when_ingest_inactive(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            run_concurrency_test(db_path=db_path, writers=1, readers=0, total_ops=50)
            vacuum_safe(db_path=db_path, ingest_active=False)
            self.assertTrue(sqlite_integrity_check(db_path))
            with self.assertRaises(RuntimeError):
                vacuum_safe(db_path=db_path, ingest_active=True)

    def test_chaos_smoke_scenarios(self) -> None:
        kill9 = chaos_kill9_smoke()
        self.assertTrue(kill9["integrity_ok"])
        self.assertEqual(kill9["result"]["write_errors"], [])
        self.assertEqual(kill9["result"]["read_errors"], [])

        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "core.sqlite3"
            status, event = chaos_disk_full_smoke(db_path=db_path)
            self.assertEqual(status.http_status, 503)
            self.assertGreaterEqual(status.retry_after_ms, 0)
            self.assertEqual(event["kind"], "observability_gap.storage_disk_full")

            backups = Path(tmp) / "backups"
            status2, events = chaos_wal_corruption_smoke(db_path=db_path, backups_dir=backups)
            self.assertEqual(status2.http_status, 503)
            self.assertTrue(any(e["kind"] == "observability_gap.storage_corrupted" for e in events))


if __name__ == "__main__":
    unittest.main()
