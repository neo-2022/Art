#!/usr/bin/env bash
set -euo pipefail

wait_for_http_ok() {
  local url="${1:?url required}"
  local attempts="${2:-60}"
  local delay="${3:-1}"
  local out_file="${4:-/dev/null}"
  local i
  for i in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >"$out_file" 2>/dev/null; then
      return 0
    fi
    sleep "$delay"
  done
  echo "timeout waiting for $url" >&2
  return 1
}

build_static_runtime_binaries() {
  rustup target add x86_64-unknown-linux-musl >/dev/null 2>&1 || true
  cargo build -p art-core --profile general --target x86_64-unknown-linux-musl --locked
  cargo build -p art-agent --profile general --target x86_64-unknown-linux-musl --locked
}

run_core_http_smoke() {
  local base_url="${1:?base url required}"
  local artifacts_dir="${2:?artifacts dir required}"
  local trace_id="${3:-trace-platform-smoke}"
  mkdir -p "$artifacts_dir"

  curl -fsS "${base_url}/health" | tee "$artifacts_dir/core-health.json" >/dev/null
  jq -e '.status == "ok"' "$artifacts_dir/core-health.json" >/dev/null

  curl -fsS -X POST "${base_url}/api/v1/ingest" \
    -H 'content-type: application/json' \
    -d "{\"events\":[{\"kind\":\"smoke.test\",\"severity\":\"info\",\"payload\":{\"ok\":true},\"message\":\"platform smoke event\",\"scope\":\"platform-smoke\",\"trace_id\":\"${trace_id}\",\"ts_ms\":1234567890}]}" \
    | tee "$artifacts_dir/core-ingest.json" >/dev/null
  jq -e '.accepted == 1 and .invalid == 0' "$artifacts_dir/core-ingest.json" >/dev/null

  curl -fsS "${base_url}/api/v1/snapshot" | tee "$artifacts_dir/core-snapshot.json" >/dev/null
  jq -e --arg trace_id "$trace_id" 'any(.events[]?; .event.trace_id == $trace_id and .event.kind == "smoke.test")' \
    "$artifacts_dir/core-snapshot.json" >/dev/null

  curl -fsS -N -H 'x-core-stream-hold-seconds: 1' "${base_url}/api/v1/stream" \
    >"$artifacts_dir/core-stream.txt"
  grep -q '"kind":"smoke.test"' "$artifacts_dir/core-stream.txt"

  curl -fsS -X POST "${base_url}/api/v1/actions/simulate" \
    -H 'content-type: application/json' \
    -H 'x-action-preflight-id: pf-platform-smoke' \
    -H 'x-actor-role: admin' \
    -H 'x-mcp-mode: full_admin' \
    -d '{"action":"noop","target":"platform-smoke"}' \
    | tee "$artifacts_dir/core-action-simulate.json" >/dev/null
  jq -e '.ok == true and .policy_verdict.allowed == true and .preflight.provided == true' \
    "$artifacts_dir/core-action-simulate.json" >/dev/null

  curl -fsS -X POST "${base_url}/api/v1/actions/execute" \
    -H 'content-type: application/json' \
    -H 'x-action-preflight-id: pf-platform-smoke' \
    -H 'x-actor-role: admin' \
    -H 'x-mcp-mode: full_admin' \
    -d '{"action":"noop","target":"platform-smoke"}' \
    | tee "$artifacts_dir/core-action-execute.json" >/dev/null
  jq -e '.accepted == true and .action == "noop" and .audit_attach.merkle_proof.root_hash != ""' \
    "$artifacts_dir/core-action-execute.json" >/dev/null

  curl -fsS "${base_url}/api/v1/audit/verify" \
    -H 'x-actor-role: admin' \
    | tee "$artifacts_dir/core-audit-verify.json" >/dev/null
  jq -e '.ok == true' "$artifacts_dir/core-audit-verify.json" >/dev/null
}

run_agent_http_smoke() {
  local base_url="${1:?base url required}"
  local artifacts_dir="${2:?artifacts dir required}"
  mkdir -p "$artifacts_dir"

  curl -fsS "${base_url}/health" | tee "$artifacts_dir/agent-health.json" >/dev/null
  jq -e '.status == "ok"' "$artifacts_dir/agent-health.json" >/dev/null

  curl -fsS -X POST "${base_url}/api/v1/agent/spool/enqueue" \
    -H 'content-type: application/json' \
    -d '{"count":1,"bytes":64,"payload":{"kind":"agent.platform.smoke"}}' \
    | tee "$artifacts_dir/agent-enqueue.json" >/dev/null
  jq -e '.ok == true' "$artifacts_dir/agent-enqueue.json" >/dev/null

  curl -fsS "${base_url}/api/v1/agent/spool/status" | tee "$artifacts_dir/agent-spool-status.json" >/dev/null
  jq -e '.pending >= 1' "$artifacts_dir/agent-spool-status.json" >/dev/null
}
