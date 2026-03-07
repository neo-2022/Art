#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVICE_PATH="$ROOT_DIR/systemd/art-vacuum.service"
TIMER_PATH="$ROOT_DIR/systemd/art-vacuum.timer"
TMP_DIR="$(mktemp -d)"
DB_PATH="$TMP_DIR/core.sqlite3"
INGEST_FLAG="$TMP_DIR/ingest_active.flag"
MISSING_DB_PATH="$TMP_DIR/missing/core.sqlite3"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

service_shell_command() {
  python3 - "$SERVICE_PATH" <<'PY'
from __future__ import annotations
import shlex
import sys
from pathlib import Path

for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if line.startswith("ExecStart="):
        command = line.split("=", 1)[1].strip()
        parts = shlex.split(command)
        if len(parts) >= 4 and parts[:3] == ["/usr/bin/env", "bash", "-c"]:
            print(parts[3])
            raise SystemExit(0)
        raise SystemExit(f"unsupported ExecStart shape: {command}")
        raise SystemExit(0)
raise SystemExit("ExecStart not found")
PY
}

run_service() {
  local db_path="$1"
  local ingest_flag="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  local shell_command
  shell_command="$(service_shell_command)"
  ART_CORE_DB_PATH="$db_path" \
  ART_INGEST_ACTIVE_FILE="$ingest_flag" \
  ART_VACUUM_SCHEDULE="Sunday_03:30" \
    bash -c "$shell_command" >"$stdout_file" 2>"$stderr_file"
}

echo "[stage11-vacuum] verify systemd units"
systemd-analyze verify "$SERVICE_PATH" "$TIMER_PATH" >/dev/null

echo "[stage11-vacuum] prepare WAL-enabled sqlite db"
python3 - "$DB_PATH" <<'PY'
from __future__ import annotations
import sqlite3
import sys
from pathlib import Path

db_path = Path(sys.argv[1])
conn = sqlite3.connect(str(db_path))
try:
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("CREATE TABLE IF NOT EXISTS events(id INTEGER PRIMARY KEY, payload TEXT NOT NULL);")
    conn.execute("INSERT INTO events(payload) VALUES ('vacuum-smoke');")
    conn.commit()
finally:
    conn.close()
PY

SUCCESS_STDOUT="$TMP_DIR/success.stdout"
SUCCESS_STDERR="$TMP_DIR/success.stderr"
echo "[stage11-vacuum] run success path"
run_service "$DB_PATH" "$INGEST_FLAG" "$SUCCESS_STDOUT" "$SUCCESS_STDERR"
grep -q "vacuum_status=ok" "$SUCCESS_STDOUT"
test ! -s "$SUCCESS_STDERR"

python3 - "$DB_PATH" <<'PY'
from __future__ import annotations
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
try:
    row = conn.execute("PRAGMA integrity_check;").fetchone()
    assert row and row[0] == "ok", row
finally:
    conn.close()
PY

SKIP_STDOUT="$TMP_DIR/skip.stdout"
SKIP_STDERR="$TMP_DIR/skip.stderr"
echo "1" >"$INGEST_FLAG"
echo "[stage11-vacuum] run safe-skip path"
run_service "$DB_PATH" "$INGEST_FLAG" "$SKIP_STDOUT" "$SKIP_STDERR"
grep -q "vacuum_status=skipped reason=ingest_active" "$SKIP_STDOUT"
test ! -s "$SKIP_STDERR"
rm -f "$INGEST_FLAG"

MISSING_STDOUT="$TMP_DIR/missing.stdout"
MISSING_STDERR="$TMP_DIR/missing.stderr"
echo "[stage11-vacuum] run missing-db failure path"
if run_service "$MISSING_DB_PATH" "$INGEST_FLAG" "$MISSING_STDOUT" "$MISSING_STDERR"; then
  echo "expected missing-db path to fail" >&2
  exit 1
fi
python3 - "$MISSING_STDERR" "$MISSING_DB_PATH" <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8").strip())
assert payload["kind"] == "observability_gap.storage_vacuum_failed", payload
assert payload["where"] == "core/storage", payload
assert payload["why"] == "missing_db_file", payload
assert payload["evidence"]["db_path"] == sys.argv[2], payload
assert payload["evidence"]["schedule"] == "Sunday_03:30", payload
assert payload["evidence"]["trace_id"], payload
PY

cat <<EOF
{
  "verify": "ok",
  "success_path": "ok",
  "safe_skip": "ok",
  "missing_db_gap": "ok",
  "timer_schedule": "Sun 03:30",
  "unit": "art-vacuum.service",
  "timer": "art-vacuum.timer"
}
EOF
