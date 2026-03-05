#!/usr/bin/env bash
set -euo pipefail

PORT="${AGENT_RECEIVERS_CHAOS_PORT:-18072}"
BASE_URL="http://127.0.0.1:${PORT}"
TMP_DIR="$(mktemp -d)"
AGENT_PID=""

cleanup() {
  if [[ -n "${AGENT_PID}" ]] && kill -0 "${AGENT_PID}" 2>/dev/null; then
    kill "${AGENT_PID}" 2>/dev/null || true
    wait "${AGENT_PID}" 2>/dev/null || true
  fi
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

wait_health() {
  for _ in $(seq 1 100); do
    if curl -fsS "${BASE_URL}/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  echo "agent receivers chaos: health timeout" >&2
  return 1
}

RUST_LOG=warn AGENT_PORT="${PORT}" cargo run -p art-agent >"${TMP_DIR}/agent.log" 2>&1 &
AGENT_PID=$!
wait_health

python3 - "${BASE_URL}" <<'PY'
import json
import sys
import urllib.error
import urllib.request

base_url = sys.argv[1]

def post(path: str, payload: dict):
    req = urllib.request.Request(
        base_url + path,
        data=json.dumps(payload).encode("utf-8"),
        headers={"content-type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return resp.getcode(), json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8") if exc.fp else "{}"
        return exc.code, json.loads(body or "{}")

code, _ = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "file_tail",
    "source": "permission_denied",
})
assert code == 403, f"expected 403 permission_denied, got {code}"

code, _ = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "stdout_stderr",
    "source": "spawn_failed",
})
assert code == 400, f"expected 400 spawn_failed, got {code}"

code, _ = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "unknown_receiver",
    "source": "line",
})
assert code == 400, f"expected 400 unknown_receiver, got {code}"

code, _ = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "journald",
    "source": "{bad-json}",
})
assert code == 200, f"expected 200 parse fail payload, got {code}"

long_line = "A" * 70000
code, _ = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "journald",
    "source": long_line,
    "multiline": True,
})
assert code == 200, f"expected 200 multiline truncation payload, got {code}"

code, body = post("/api/v1/agent/receivers/parse", {
    "receiver_kind": "file_tail",
    "source": "token=supersecret",
})
assert code == 200, f"expected 200 redaction payload, got {code}"
events = body.get("events", [])
assert events, "expected at least one parsed event for redaction check"
raw_line = events[0].get("payload", {}).get("raw_line")
assert raw_line == "***redacted***", f"expected redacted raw_line, got {raw_line!r}"

with urllib.request.urlopen(base_url + "/api/v1/agent/spool/events", timeout=5) as resp:
    data = json.loads(resp.read().decode("utf-8"))

kinds = [event.get("kind") for event in data.get("events", [])]
required = {
    "observability_gap.receiver_permission_denied",
    "observability_gap.receiver_process_spawn_failed",
    "observability_gap.receiver_read_failed",
    "data_quality.receiver_parse_failed",
    "data_quality.receiver_multiline_truncated",
}
missing = sorted(required.difference(kinds))
assert not missing, f"missing receiver chaos events: {missing}"
PY

echo "agent-receivers-chaos-runtime: OK"
