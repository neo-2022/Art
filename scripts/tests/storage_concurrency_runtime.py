#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.storage_stage11 import run_concurrency_test


def main() -> int:
    writers = 8
    readers = 4
    total_ops = 10000
    started = time.monotonic()
    with tempfile.TemporaryDirectory() as tmp:
        db_path = Path(tmp) / "core.sqlite3"
        result = run_concurrency_test(
            db_path=db_path,
            writers=writers,
            readers=readers,
            total_ops=total_ops,
        )
    elapsed_seconds = round(time.monotonic() - started, 3)

    summary = {
        "writers": result["writers"],
        "readers": result["readers"],
        "ops_target": result["ops_target"],
        "elapsed_seconds": elapsed_seconds,
        "accepted": result["accepted"],
        "committed": result["committed"],
        "db_count": result["db_count"],
        "write_errors": result["write_errors"],
        "read_errors": result["read_errors"],
        "database_locked_fatal": any(
            "database is locked" in err for err in result["write_errors"] + result["read_errors"]
        ),
    }

    print(json.dumps(summary, ensure_ascii=True, indent=2))

    assert summary["writers"] >= 8
    assert summary["readers"] >= 4
    assert summary["ops_target"] >= 10000
    assert summary["accepted"] == summary["ops_target"]
    assert summary["committed"] == summary["db_count"]
    assert summary["write_errors"] == []
    assert summary["read_errors"] == []
    assert not summary["database_locked_fatal"]
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
