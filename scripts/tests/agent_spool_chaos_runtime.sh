#!/usr/bin/env bash
set -euo pipefail

PORT="${AGENT_CHAOS_PORT:-18071}"
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
  echo "agent health check timeout" >&2
  return 1
}

start_agent() {
  RUST_LOG=warn AGENT_PORT="${PORT}" cargo run -p art-agent >"${TMP_DIR}/agent.log" 2>&1 &
  AGENT_PID=$!
  wait_health
}

post_json_status() {
  local endpoint="$1"
  local payload="$2"
  local out_file="$3"
  curl -sS -o "${out_file}" -w "%{http_code}" \
    -H "content-type: application/json" \
    -X POST \
    "${BASE_URL}${endpoint}" \
    -d "${payload}"
}

start_agent

# chaos: kill -9 during write + restart
status="$(post_json_status "/api/v1/agent/spool/enqueue" '{"bytes":900,"payload":{"id":"before-kill"}}' "${TMP_DIR}/enqueue_before.json")"
[[ "${status}" == "200" ]] || { echo "enqueue before kill failed: ${status}" >&2; exit 1; }
kill -9 "${AGENT_PID}"
wait "${AGENT_PID}" 2>/dev/null || true
AGENT_PID=""
start_agent

# chaos: full capacity -> never_drop_unacked rejection + gap
status="$(post_json_status "/api/v1/agent/spool/enqueue" '{"bytes":900,"payload":{"id":"fill"}}' "${TMP_DIR}/enqueue_fill.json")"
[[ "${status}" == "200" ]] || { echo "fill enqueue failed: ${status}" >&2; exit 1; }
status="$(post_json_status "/api/v1/agent/spool/enqueue" '{"bytes":300,"payload":{"id":"reject"}}' "${TMP_DIR}/enqueue_reject.json")"
[[ "${status}" == "507" ]] || { echo "expected 507 for spool_full, got ${status}" >&2; exit 1; }

# chaos: disk full simulation
status="$(post_json_status "/api/v1/agent/spool/simulate_disk_full" '{}' "${TMP_DIR}/disk_full.json")"
[[ "${status}" == "507" ]] || { echo "expected 507 for disk_full, got ${status}" >&2; exit 1; }

# chaos: corruption simulation
status="$(post_json_status "/api/v1/agent/spool/simulate_corruption" '{"corruption_type":"sqlite_header"}' "${TMP_DIR}/corruption.json")"
[[ "${status}" == "200" ]] || { echo "expected 200 for corruption simulation, got ${status}" >&2; exit 1; }

events_file="${TMP_DIR}/events.json"
curl -fsS "${BASE_URL}/api/v1/agent/spool/events" >"${events_file}"
grep -q '"observability_gap.spool_full"' "${events_file}"
grep -q '"observability_gap.spool_disk_full"' "${events_file}"
grep -q '"observability_gap.spool_corrupted"' "${events_file}"

echo "agent-spool-chaos-runtime: OK"
