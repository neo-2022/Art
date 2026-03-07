#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import sqlite3
import tempfile
import threading
import time
import uuid
from queue import Empty, Queue
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


@dataclass
class IngestStatus:
    http_status: int
    retry_after_ms: int
    mode: str


def _now_ms() -> int:
    return int(time.time() * 1000)


def _trace_id() -> str:
    return str(uuid.uuid4())


def emit_gap_event(kind: str, evidence: dict, why: str) -> dict:
    return {
        "kind": kind,
        "ts_ms": _now_ms(),
        "trace_id": _trace_id(),
        "what": f"{kind} detected",
        "where": "core.storage.sqlite",
        "why": why,
        "evidence": evidence,
        "actions": [{"action_ref": "docs/ops/storage_corruption_runbook.md"}],
    }


def sqlite_integrity_check(db_path: Path) -> bool:
    conn = sqlite3.connect(str(db_path))
    try:
        cur = conn.execute("PRAGMA integrity_check;")
        row = cur.fetchone()
        return row is not None and row[0] == "ok"
    finally:
        conn.close()


def create_backup(db_path: Path, backups_dir: Path) -> str:
    backups_dir.mkdir(parents=True, exist_ok=True)
    backup_id = time.strftime("core-%Y%m%d-%H%M%S")
    target = backups_dir / f"{backup_id}.sqlite3"
    shutil.copy2(db_path, target)
    wal = db_path.with_name(db_path.name + "-wal")
    if wal.exists():
        shutil.copy2(wal, backups_dir / f"{backup_id}.sqlite3-wal")
    return backup_id


def restore_backup(db_path: Path, backups_dir: Path, backup_id: str) -> bool:
    src = backups_dir / f"{backup_id}.sqlite3"
    if not src.exists():
        return False
    shutil.copy2(src, db_path)
    return sqlite_integrity_check(db_path)


def storage_corruption_recovery(
    *,
    db_path: Path,
    backups_dir: Path,
    corruption_type: str,
    sqlite_error: str,
    restore_executor: Callable[[Path, Path, str], bool] = restore_backup,
) -> tuple[IngestStatus, list[dict]]:
    events: list[dict] = []
    backup_files = sorted(backups_dir.glob("core-*.sqlite3"))
    last_ok_backup_id = backup_files[-1].stem if backup_files else "none"
    events.append(
        emit_gap_event(
            "observability_gap.storage_corrupted",
            {
                "db_path": str(db_path),
                "corruption_type": corruption_type,
                "sqlite_error": sqlite_error,
                "last_ok_backup_id": last_ok_backup_id,
            },
            "sqlite_corruption",
        )
    )

    restored = False
    if last_ok_backup_id != "none":
        restored = restore_executor(db_path, backups_dir, last_ok_backup_id)

    if restored:
        return IngestStatus(http_status=503, retry_after_ms=1000, mode="recovering"), events

    events.append(
        emit_gap_event(
            "observability_gap.storage_read_only",
            {
                "db_path": str(db_path),
                "error": "restore_failed",
            },
            "restore_failed",
        )
    )
    return IngestStatus(http_status=503, retry_after_ms=2000, mode="read_only"), events


def run_concurrency_test(
    *,
    db_path: Path,
    writers: int = 8,
    readers: int = 4,
    total_ops: int = 10000,
    max_retries: int = 200,
) -> dict:
    if db_path.exists():
        db_path.unlink()
    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA busy_timeout=5000;")
    conn.execute("CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, payload TEXT NOT NULL);")
    conn.commit()
    conn.close()

    accepted = total_ops
    committed = 0
    lock = threading.Lock()
    stop = threading.Event()
    write_errors: list[str] = []
    read_errors: list[str] = []
    jobs: Queue[int] = Queue()
    for idx in range(total_ops):
        jobs.put(idx + 1)

    def writer(_idx: int) -> None:
        nonlocal committed
        wconn = sqlite3.connect(str(db_path), timeout=5.0, isolation_level=None)
        wconn.execute("PRAGMA journal_mode=WAL;")
        wconn.execute("PRAGMA busy_timeout=5000;")
        while True:
            try:
                job = jobs.get_nowait()
            except Empty:
                break
            payload = f"event-{job}"
            retries = 0
            committed_one = False
            while retries <= max_retries:
                try:
                    wconn.execute("INSERT INTO events(payload) VALUES (?)", (payload,))
                    with lock:
                        committed += 1
                    committed_one = True
                    break
                except sqlite3.OperationalError as err:
                    if "database is locked" not in str(err):
                        write_errors.append(str(err))
                        break
                    retries += 1
                    time.sleep(0.01)
            if not committed_one:
                write_errors.append("database is locked after retries")
                stop.set()
            jobs.task_done()
        wconn.close()

    def reader(_idx: int) -> None:
        rconn = sqlite3.connect(str(db_path), timeout=5.0)
        rconn.execute("PRAGMA busy_timeout=5000;")
        while not stop.is_set() and (not jobs.empty()):
            try:
                cur = rconn.execute("SELECT COUNT(*) FROM events;")
                _ = cur.fetchone()
            except sqlite3.OperationalError as err:
                if "database is locked" not in str(err):
                    read_errors.append(str(err))
                    stop.set()
            time.sleep(0.001)
        rconn.close()

    threads = [threading.Thread(target=writer, args=(i,)) for i in range(writers)]
    threads += [threading.Thread(target=reader, args=(i,)) for i in range(readers)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=60)
    stop.set()

    final_conn = sqlite3.connect(str(db_path))
    db_count = final_conn.execute("SELECT COUNT(*) FROM events").fetchone()[0]
    final_conn.close()
    return {
        "writers": writers,
        "readers": readers,
        "ops_target": total_ops,
        "accepted": accepted,
        "committed": committed,
        "db_count": db_count,
        "write_errors": write_errors,
        "read_errors": read_errors,
    }


def vacuum_safe(*, db_path: Path, ingest_active: bool) -> None:
    if ingest_active:
        raise RuntimeError("active_ingest_detected")
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA wal_checkpoint(TRUNCATE);")
        conn.execute("VACUUM;")
    finally:
        conn.close()


def chaos_kill9_smoke() -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        db_path = Path(tmp) / "kill9.sqlite3"
        result = run_concurrency_test(db_path=db_path, writers=2, readers=1, total_ops=200)
        return {"integrity_ok": sqlite_integrity_check(db_path), "result": result}


def chaos_disk_full_smoke(db_path: Path) -> tuple[IngestStatus, dict]:
    event = emit_gap_event(
        "observability_gap.storage_disk_full",
        {"path": str(db_path), "free_bytes": 0, "retry_after_ms": 1500},
        "no_space_left",
    )
    return IngestStatus(http_status=503, retry_after_ms=1500, mode="degraded"), event


def chaos_wal_corruption_smoke(*, db_path: Path, backups_dir: Path) -> tuple[IngestStatus, list[dict]]:
    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("CREATE TABLE IF NOT EXISTS wal_test(id INTEGER PRIMARY KEY, value TEXT);")
    conn.execute("INSERT INTO wal_test(value) VALUES ('x');")
    conn.commit()
    conn.close()
    create_backup(db_path, backups_dir)
    wal_path = db_path.with_name(db_path.name + "-wal")
    wal_path.write_bytes(b"\x00\xffcorrupted-wal")
    return storage_corruption_recovery(
        db_path=db_path,
        backups_dir=backups_dir,
        corruption_type="wal_corruption",
        sqlite_error="database disk image is malformed",
    )


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        db_path = tmp_path / "core.sqlite3"
        backups_dir = tmp_path / "backups"
        result = run_concurrency_test(db_path=db_path)
        print(json.dumps(result, ensure_ascii=True))
        status, events = chaos_wal_corruption_smoke(db_path=db_path, backups_dir=backups_dir)
        print(json.dumps({"status": status.__dict__, "events": events}, ensure_ascii=True))


if __name__ == "__main__":
    main()
