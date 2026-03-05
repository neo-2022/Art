#!/usr/bin/env bash
set -euo pipefail

emit_event() {
  local event_name="$1"
  local reason="$2"
  local stage="${3:-export}"
  python3 - "$event_name" "$reason" "$stage" <<'PY' >&2
import json
import sys
import time

event_name, reason, stage = sys.argv[1:4]
payload = {
    "event_name": event_name,
    "component": "compliance/export",
    "reason": reason,
    "stage": stage,
    "trace_id": f"trace-export-{int(time.time() * 1000)}",
}
print(json.dumps(payload, ensure_ascii=False))
PY
}

emit_cross_border_blocked() {
  local export_target="$1"
  local rule_id="$2"
  local effective_profile_id="${3:-ru}"
  python3 - "$export_target" "$rule_id" "$effective_profile_id" <<'PY' >&2
import json
import os
import sys
import time

export_target, rule_id, effective_profile_id = sys.argv[1:4]
payload = {
    "event_name": "observability_gap.cross_border_export_blocked",
    "effective_profile_id": effective_profile_id,
    "export_target": export_target,
    "rule_id": rule_id,
    "actor_id": os.environ.get("ACTOR_ID", "unknown"),
    "trace_id": f"trace-export-{int(time.time() * 1000)}",
}
print(json.dumps(payload, ensure_ascii=False))
PY
}

FROM=""
TO=""
OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      FROM="$2"
      shift 2
      ;;
    --to)
      TO="$2"
      shift 2
      ;;
    --out_dir)
      OUT="$2"
      shift 2
      ;;
    *)
      emit_event "observability_gap.export_failed" "unknown_arg:$1" "args"
      exit 2
      ;;
  esac
done

if [[ -z "$FROM" || -z "$TO" || -z "$OUT" ]]; then
  emit_event "observability_gap.export_failed" "missing_args" "args"
  exit 1
fi

if [[ "${EFFECTIVE_PROFILE_ID:-}" == "ru" ]]; then
  emit_cross_border_blocked "$OUT" "ru_env_profile_block"
  exit 1
fi

if ! python3 - "$FROM" "$TO" <<'PY' >/dev/null 2>&1; then
from datetime import datetime, timezone
import sys

def parse_iso(value: str) -> datetime:
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt

start = parse_iso(sys.argv[1])
end = parse_iso(sys.argv[2])
if start > end:
    raise ValueError("from > to")
PY
  emit_event "observability_gap.export_failed" "invalid_time_window" "args"
  exit 1
fi

if [[ "${FORCE_EXPORT_FAIL:-0}" == "1" ]]; then
  emit_event "observability_gap.export_failed" "forced_failure" "script"
  exit 1
fi

CORE_BASE_URL="${CORE_BASE_URL:-http://127.0.0.1:${CORE_PORT:-7070}}"
TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

INCIDENTS_RAW="$TMP_DIR/incidents_response.json"
AUDIT_RAW="$TMP_DIR/audit_response.json"
SNAPSHOT_RAW="$TMP_DIR/snapshot_response.json"

if ! curl -fsS -H "x-actor-role: admin" "${CORE_BASE_URL}/api/v1/incidents" >"$INCIDENTS_RAW"; then
  emit_event "observability_gap.export_failed" "incidents_fetch_failed" "fetch"
  exit 1
fi
if ! curl -fsS -H "x-actor-role: admin" "${CORE_BASE_URL}/api/v1/audit" >"$AUDIT_RAW"; then
  emit_event "observability_gap.export_failed" "audit_fetch_failed" "fetch"
  exit 1
fi
if ! curl -fsS -H "x-actor-role: admin" "${CORE_BASE_URL}/api/v1/snapshot" >"$SNAPSHOT_RAW"; then
  emit_event "observability_gap.export_failed" "snapshot_fetch_failed" "fetch"
  exit 1
fi

SNAPSHOT_PROFILE="$(
  python3 - "$SNAPSHOT_RAW" <<'PY'
import json
import pathlib
import sys

doc = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
print(doc.get("effective_profile_id", "global"))
PY
)"

if [[ "$SNAPSHOT_PROFILE" == "ru" ]]; then
  if [[ "$OUT" == *"://"* ]]; then
    emit_cross_border_blocked "$OUT" "ru_disallow_remote_target" "$SNAPSHOT_PROFILE"
    exit 1
  fi
  RU_ALLOWLIST_ROOT="${RU_EXPORT_ALLOWLIST_ROOT:-/var/lib/art/ru_exports}"
  OUT_ABS="$(
    python3 - "$OUT" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).expanduser().resolve())
PY
  )"
  ROOT_ABS="$(
    python3 - "$RU_ALLOWLIST_ROOT" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).expanduser().resolve())
PY
  )"
  case "$OUT_ABS" in
    "$ROOT_ABS"|"$ROOT_ABS"/*) ;;
    *)
      emit_cross_border_blocked "$OUT_ABS" "ru_allowlist_path_only" "$SNAPSHOT_PROFILE"
      exit 1
      ;;
  esac
fi

mkdir -p "$OUT"
if ! python3 - "$INCIDENTS_RAW" "$AUDIT_RAW" "$SNAPSHOT_RAW" "$OUT" "$FROM" "$TO" <<'PY'
import csv
import hashlib
import json
import os
import pathlib
import sys
from datetime import datetime, timezone

incidents_path = pathlib.Path(sys.argv[1])
audit_path = pathlib.Path(sys.argv[2])
snapshot_path = pathlib.Path(sys.argv[3])
out = pathlib.Path(sys.argv[4])
from_ts = sys.argv[5]
to_ts = sys.argv[6]

def parse_iso(value: str) -> datetime:
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt

window_from = int(parse_iso(from_ts).timestamp() * 1000)
window_to = int(parse_iso(to_ts).timestamp() * 1000)

incidents_doc = json.loads(incidents_path.read_text(encoding="utf-8"))
audit_doc = json.loads(audit_path.read_text(encoding="utf-8"))
snapshot_doc = json.loads(snapshot_path.read_text(encoding="utf-8"))

incidents = incidents_doc.get("items", [])
audits = audit_doc.get("items", [])
audits = [
    entry for entry in audits
    if isinstance(entry.get("timestamp"), int) and window_from <= entry["timestamp"] <= window_to
]

(out / "incidents.json").write_text(
    json.dumps(incidents, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
(out / "audit.json").write_text(
    json.dumps(audits, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

with (out / "incidents.csv").open("w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=[
            "id",
            "status",
            "kind",
            "severity",
            "action_ref",
            "run_id",
            "trace_id",
            "span_id",
        ],
    )
    writer.writeheader()
    for row in incidents:
        writer.writerow({k: row.get(k) for k in writer.fieldnames})

with (out / "audit.csv").open("w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=[
            "id",
            "timestamp",
            "actor_id",
            "actor_role",
            "mcp_mode",
            "action",
            "target",
            "result",
            "trace_id",
            "evidence_ref",
            "client_ip",
            "user_agent",
            "prev_hash",
            "entry_hash",
        ],
    )
    writer.writeheader()
    for row in audits:
        writer.writerow({k: row.get(k) for k in writer.fieldnames})

meta = {
    "build_id": (
        os.environ.get("BUILD_ID")
        or os.environ.get("GITHUB_SHA")
        or "local"
    ),
    "effective_profile_id": snapshot_doc.get(
        "effective_profile_id",
        os.environ.get("EFFECTIVE_PROFILE_ID", "global"),
    ),
    "export_window": {"from": from_ts, "to": to_ts},
    "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "core_base_url": os.environ.get("CORE_BASE_URL", ""),
    "incident_filter": "all_without_timestamp",
}
(out / "meta.json").write_text(
    json.dumps(meta, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

checks = []
for name in ["incidents.json", "incidents.csv", "audit.json", "audit.csv", "meta.json"]:
    digest = hashlib.sha256((out / name).read_bytes()).hexdigest()
    checks.append(f"{digest}  {name}")
(out / "checksums.txt").write_text("\n".join(checks) + "\n", encoding="utf-8")
PY
then
  emit_event "observability_gap.export_failed" "serialize_failed" "build_pack"
  exit 1
fi

echo "export-audit-pack: OK ($OUT)"
