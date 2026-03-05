#!/usr/bin/env bash
set -euo pipefail

has_pattern() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -F -q "$pattern" "$file"
  else
    grep -F -q "$pattern" "$file"
  fi
}

OPENAPI_FILE="docs/api/openapi.yaml"

test -s "$OPENAPI_FILE"

required_paths=(
  "/api/v1/ingest"
  "/api/v1/snapshot"
  "/api/v1/stream"
  "/api/v1/incidents"
  "/api/v1/incidents/{id}/ack"
  "/api/v1/incidents/{id}/resolve"
  "/api/v1/actions/execute"
  "/health"
  "/metrics"
)

for path in "${required_paths[@]}"; do
  has_pattern "$path" "$OPENAPI_FILE"
done

has_pattern "'413'" "$OPENAPI_FILE"
has_pattern "'429'" "$OPENAPI_FILE"
has_pattern "'503'" "$OPENAPI_FILE"
has_pattern "retry_after_ms" "$OPENAPI_FILE"

echo "stage08 openapi gate: OK"
