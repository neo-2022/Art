#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT_DIR/target/debug/art-core"
TMP_DIR="$(mktemp -d)"
PORT="${CORE_PORT:-18112}"
STARTUP_TIMEOUT_SECONDS="${CORE_STARTUP_TIMEOUT_SECONDS:-120}"
CORE_PID=""
HARD_LIMIT_START_BYTES=$((256 * 1024))
HARD_LIMIT_RECOVERY_BYTES=$((8 * 1024 * 1024))

cleanup() {
  if [[ -n "$CORE_PID" ]] && kill -0 "$CORE_PID" >/dev/null 2>&1; then
    kill "$CORE_PID" >/dev/null 2>&1 || true
    wait "$CORE_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wait_http_ok() {
  local url="$1"
  local timeout_seconds="${2:-60}"
  local deadline=$(( $(date +%s) + timeout_seconds ))
  while (( $(date +%s) < deadline )); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  echo "timeout waiting for $url" >&2
  return 1
}

write_config_global() {
  cat >"$1" <<'EOF'
profile_id = "global"
retention_days = 30
export_mode = "standard"
egress_policy = "controlled"
residency = "any"
updates_mode = "online"
EOF
}

compute_pressure_env() {
  python3 - "$TMP_DIR" <<'PY'
from __future__ import annotations
import os
import sys
from pathlib import Path

target = Path(sys.argv[1])
stats = os.statvfs(target)
free_bytes = stats.f_bavail * stats.f_frsize
mb = 1024 * 1024
free_mb = free_bytes // mb
if free_mb <= 96:
    raise SystemExit(f"not enough free space for storage pressure smoke: {free_mb}MB")
reserve_mb = free_mb - 64
print(f"{free_bytes}|{reserve_mb}")
PY
}

write_non_sparse_file_mb() {
  local path="$1"
  local size_mb="$2"
  python3 - "$path" "$size_mb" <<'PY'
from __future__ import annotations
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
target_bytes = int(sys.argv[2]) * 1024 * 1024
chunk = b"Z" * (1024 * 1024)
with path.open("wb") as fh:
    written = 0
    while written < target_bytes:
        piece = chunk[: min(len(chunk), target_bytes - written)]
        fh.write(piece)
        written += len(piece)
    fh.flush()
    os.fsync(fh.fileno())
PY
}

json_field() {
  local file="$1"
  local expr="$2"
  python3 - "$file" "$expr" <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expr = sys.argv[2]
value = payload
for part in expr.split("."):
    if part:
        value = value[part]
if isinstance(value, (dict, list)):
    print(json.dumps(value, ensure_ascii=False))
else:
    print(value)
PY
}

assert_snapshot_has_pressure_state() {
  local file="$1"
  local expected="$2"
  python3 - "$file" "$expected" <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

snapshot = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = sys.argv[2]
events = snapshot.get("events", [])
for row in events:
    event = row.get("event", {})
    if (
        event.get("kind") == "observability_gap.storage_pressure_high"
        and event.get("details", {}).get("pressure_state") == expected
    ):
        raise SystemExit(0)
raise SystemExit(f"storage pressure snapshot missing state={expected}")
PY
}

post_ingest() {
  local file="$1"
  local payload="$2"
  curl -sS -o "$file" -w "%{http_code}" \
    -H "content-type: application/json" \
    -d "$payload" \
    "http://127.0.0.1:${PORT}/api/v1/ingest"
}

start_core() {
  local cfg="$1"
  local db_path="$2"
  local analytics_path="$3"
  local log_path="$4"
  local reserve_mb="$5"
  local hard_limit_bytes="${6:-}"
  CORE_CONFIG_PATH="$cfg" \
  CORE_PORT="$PORT" \
  CORE_HOST="127.0.0.1" \
  CORE_DB_PATH="$db_path" \
  CORE_ANALYTICS_STATE_PATH="$analytics_path" \
  CORE_STORAGE_RESERVED_FREE_SPACE_MB="$reserve_mb" \
  CORE_STORAGE_MAX_DB_BYTES="$hard_limit_bytes" \
  "$BIN" >"$log_path" 2>&1 &
  CORE_PID="$!"
  wait_http_ok "http://127.0.0.1:${PORT}/health" "$STARTUP_TIMEOUT_SECONDS"
}

compute_backup_dir() {
  python3 - "$1" <<'PY'
from __future__ import annotations
import hashlib
import os
import sys
from pathlib import Path

db_path = Path(sys.argv[1]).resolve()
profile_id = "global"
tmp_dir = Path(os.getenv("TMPDIR", "/tmp")).resolve()
scope = hashlib.sha256(str(db_path).encode("utf-8")).hexdigest()[:16]
if str(db_path).startswith(str(tmp_dir)):
    root = db_path.parent / "backups" / profile_id / scope
else:
    root = Path("/var/lib/art/backups") / profile_id / scope
print(root)
PY
}

create_backup_set() {
  local db_path="$1"
  local backup_dir="$2"
  mkdir -p "$backup_dir"
  python3 - "$db_path" "$backup_dir" <<'PY'
from __future__ import annotations
import sqlite3
import sys
import time
from pathlib import Path

db_path = Path(sys.argv[1])
backup_dir = Path(sys.argv[2])
conn = sqlite3.connect(str(db_path))
try:
    for idx in range(6):
        backup_id = f"core-{idx:02d}-{int(time.time() * 1000)}"
        backup_path = backup_dir / f"{backup_id}.sqlite3"
        backup_literal = str(backup_path).replace("'", "''")
        conn.execute(f"VACUUM INTO '{backup_literal}'")
        meta_path = backup_dir / f"{backup_id}.metadata.json"
        meta_path.write_text(
            (
                '{'
                f'"backup_id":"{backup_id}",'
                '"profile_id":"global",'
                f'"db_path":"{db_path}",'
                f'"created_ts_ms":{int(time.time() * 1000)},'
                '"format":"sqlite_v1"'
                '}'
            ),
            encoding="utf-8",
        )
        time.sleep(0.002)
finally:
    conn.close()
PY
}

count_sqlite_backups() {
  find "$1" -maxdepth 1 -type f -name '*.sqlite3' | wc -l | tr -d ' '
}

echo "[stage11-pressure] build art-core"
cargo build -p art-core >/dev/null

CFG="$TMP_DIR/core.toml"
DB_PATH="$TMP_DIR/core.sqlite3"
ANALYTICS_PATH="$TMP_DIR/analytics.json"
CORE_LOG="$TMP_DIR/core.log"
FILLER_PATH="$TMP_DIR/storage-pressure.bin"
write_config_global "$CFG"

IFS='|' read -r FREE_BYTES RESERVE_MB <<<"$(compute_pressure_env)"
echo "[stage11-pressure] filesystem free bytes before start: $FREE_BYTES"
echo "[stage11-pressure] CORE_STORAGE_RESERVED_FREE_SPACE_MB=$RESERVE_MB"

start_core "$CFG" "$DB_PATH" "$ANALYTICS_PATH" "$CORE_LOG" "$RESERVE_MB" ""

HEALTH_NORMAL="$TMP_DIR/health-normal.json"
curl -fsS "http://127.0.0.1:${PORT}/health" >"$HEALTH_NORMAL"
[[ "$(json_field "$HEALTH_NORMAL" "storage_mode")" == "healthy" ]]
[[ "$(json_field "$HEALTH_NORMAL" "storage_pressure_state")" == "normal" ]]

echo "[stage11-pressure] trigger high watermark"
write_non_sparse_file_mb "$FILLER_PATH" 52

HEAVY_RESP="$TMP_DIR/heavy.json"
HEAVY_CODE="$(post_ingest "$HEAVY_RESP" '{"events":[{"severity":"info","msg":"pressure-heavy-1"},{"severity":"info","msg":"pressure-heavy-2"}]}')"
[[ "$HEAVY_CODE" == "503" ]] || { echo "expected 503 for heavy high-pressure ingest, got $HEAVY_CODE"; cat "$HEAVY_RESP"; exit 1; }
[[ "$(json_field "$HEAVY_RESP" "error")" == "storage_pressure_high" ]]
[[ "$(json_field "$HEAVY_RESP" "retry_after_ms")" == "1000" ]]

HEALTH_HIGH="$TMP_DIR/health-high.json"
curl -fsS "http://127.0.0.1:${PORT}/health" >"$HEALTH_HIGH"
[[ "$(json_field "$HEALTH_HIGH" "storage_pressure_state")" == "high" ]]

LIGHT_OK_RESP="$TMP_DIR/light-ok.json"
LIGHT_OK_CODE="$(post_ingest "$LIGHT_OK_RESP" '{"events":[{"severity":"info","msg":"pressure-light-ok"}]}')"
[[ "$LIGHT_OK_CODE" == "200" ]] || { echo "expected 200 for light high-pressure ingest, got $LIGHT_OK_CODE"; cat "$LIGHT_OK_RESP"; exit 1; }

SNAPSHOT_HIGH="$TMP_DIR/snapshot-high.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$SNAPSHOT_HIGH"
assert_snapshot_has_pressure_state "$SNAPSHOT_HIGH" "high"

echo "[stage11-pressure] trigger critical watermark"
write_non_sparse_file_mb "$FILLER_PATH" 72

CRITICAL_RESP="$TMP_DIR/critical.json"
CRITICAL_CODE="$(post_ingest "$CRITICAL_RESP" '{"events":[{"severity":"info","msg":"pressure-critical-blocked"}]}')"
[[ "$CRITICAL_CODE" == "503" ]] || { echo "expected 503 for critical-pressure ingest, got $CRITICAL_CODE"; cat "$CRITICAL_RESP"; exit 1; }
[[ "$(json_field "$CRITICAL_RESP" "error")" == "storage_pressure_critical" ]]
[[ "$(json_field "$CRITICAL_RESP" "retry_after_ms")" == "1500" ]]

HEALTH_CRITICAL="$TMP_DIR/health-critical.json"
curl -fsS "http://127.0.0.1:${PORT}/health" >"$HEALTH_CRITICAL"
[[ "$(json_field "$HEALTH_CRITICAL" "storage_pressure_state")" == "critical" ]]

SNAPSHOT_CRITICAL="$TMP_DIR/snapshot-critical.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$SNAPSHOT_CRITICAL"
assert_snapshot_has_pressure_state "$SNAPSHOT_CRITICAL" "critical"

echo "[stage11-pressure] recover after free space return"
rm -f "$FILLER_PATH"
RECOVERED=0
for _ in $(seq 1 30); do
  curl -fsS "http://127.0.0.1:${PORT}/health" >"$TMP_DIR/health-recovered.json"
  if [[ "$(json_field "$TMP_DIR/health-recovered.json" "storage_pressure_state")" == "normal" ]]; then
    RECOVERED=1
    break
  fi
  sleep 0.2
done
[[ "$RECOVERED" == "1" ]] || { echo "storage pressure did not recover to normal"; cat "$TMP_DIR/health-recovered.json"; exit 1; }
[[ "$(json_field "$TMP_DIR/health-recovered.json" "storage_mode")" == "healthy" ]]

RECOVERY_RESP="$TMP_DIR/recovery.json"
RECOVERY_CODE="$(post_ingest "$RECOVERY_RESP" '{"events":[{"severity":"info","msg":"pressure-recovered"}]}')"
[[ "$RECOVERY_CODE" == "200" ]] || { echo "expected 200 after free space recovery, got $RECOVERY_CODE"; cat "$RECOVERY_RESP"; exit 1; }

echo "[stage11-pressure] prepare archive/prune baseline"
kill "$CORE_PID" >/dev/null 2>&1 || true
wait "$CORE_PID" >/dev/null 2>&1 || true
CORE_PID=""

BACKUP_DIR="$(compute_backup_dir "$DB_PATH")"
create_backup_set "$DB_PATH" "$BACKUP_DIR"
BACKUPS_BEFORE="$(count_sqlite_backups "$BACKUP_DIR")"
if [[ ! "$BACKUPS_BEFORE" =~ ^[0-9]+$ ]] || (( BACKUPS_BEFORE < 6 )); then
  echo "expected synthetic backup set before prune, got $BACKUPS_BEFORE" >&2
  exit 1
fi

echo "[stage11-pressure] restart core with hard db limit for disk full contour"
CORE_LOG_LIMIT="$TMP_DIR/core-hard-limit.log"
start_core "$CFG" "$DB_PATH" "$ANALYTICS_PATH" "$CORE_LOG_LIMIT" "$RESERVE_MB" "$HARD_LIMIT_START_BYTES"

DISK_FULL_RESP="$TMP_DIR/disk-full.json"
DISK_FULL_SEEN=0
for idx in $(seq 1 64); do
  payload="$(python3 - "$idx" <<'PY'
from __future__ import annotations
import json
import sys
idx = sys.argv[1]
print(json.dumps({"events":[{"severity":"info","msg":f"disk-full-{idx}-" + ("x" * (64 * 1024))}]}))
PY
)"
  code="$(post_ingest "$DISK_FULL_RESP" "$payload")"
    if [[ "$code" == "503" ]]; then
    [[ "$(json_field "$DISK_FULL_RESP" "error")" == "storage_disk_full" ]]
    [[ "$(json_field "$DISK_FULL_RESP" "retry_after_ms")" == "1500" ]]
    DISK_FULL_SEEN=1
    break
  fi
  [[ "$code" == "200" ]] || { echo "unexpected status during hard-limit smoke: $code"; cat "$DISK_FULL_RESP"; exit 1; }
done
[[ "$DISK_FULL_SEEN" == "1" ]] || { echo "storage_disk_full was not reached under hard limit"; exit 1; }

SNAPSHOT_DISK_FULL="$TMP_DIR/snapshot-disk-full.json"
curl -fsS "http://127.0.0.1:${PORT}/api/v1/snapshot" >"$SNAPSHOT_DISK_FULL"
python3 - "$SNAPSHOT_DISK_FULL" <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

snapshot = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
events = snapshot.get("events", [])
kinds = [row.get("event", {}).get("kind") for row in events]
assert "observability_gap.storage_disk_full" in kinds, kinds
assert "observability_gap.storage_archive_prune_activated" in kinds, kinds
PY

BACKUPS_AFTER="$(count_sqlite_backups "$BACKUP_DIR")"
if [[ ! "$BACKUPS_AFTER" =~ ^[0-9]+$ ]] || (( BACKUPS_AFTER > 2 )); then
  echo "critical prune did not reduce backup set to <=2, got $BACKUPS_AFTER" >&2
  exit 1
fi

echo "[stage11-pressure] recover from hard db limit"
kill "$CORE_PID" >/dev/null 2>&1 || true
wait "$CORE_PID" >/dev/null 2>&1 || true
CORE_PID=""

CORE_LOG_RECOVERY="$TMP_DIR/core-hard-limit-recovery.log"
start_core "$CFG" "$DB_PATH" "$ANALYTICS_PATH" "$CORE_LOG_RECOVERY" "$RESERVE_MB" "$HARD_LIMIT_RECOVERY_BYTES"

DISK_FULL_RECOVERY_RESP="$TMP_DIR/disk-full-recovery.json"
DISK_FULL_RECOVERY_CODE="$(post_ingest "$DISK_FULL_RECOVERY_RESP" '{"events":[{"severity":"info","msg":"disk-full-recovered"}]}')"
[[ "$DISK_FULL_RECOVERY_CODE" == "200" ]] || { echo "expected 200 after hard-limit recovery, got $DISK_FULL_RECOVERY_CODE"; cat "$DISK_FULL_RECOVERY_RESP"; exit 1; }

echo "stage11-storage-pressure-runtime: OK"
echo "reserved_free_space_mb=$RESERVE_MB"
echo "high_filler_mb=52"
echo "critical_filler_mb=72"
echo "hard_limit_start_bytes=$HARD_LIMIT_START_BYTES"
echo "hard_limit_recovery_bytes=$HARD_LIMIT_RECOVERY_BYTES"
echo "backups_before_prune=$BACKUPS_BEFORE"
echo "backups_after_prune=$BACKUPS_AFTER"
