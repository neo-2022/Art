#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

for f in docker/core.Dockerfile docker/agent.Dockerfile; do
  test -s "$f"
  grep -q '^FROM scratch$' "$f"
  grep -q '^COPY \${BIN_PATH} /' "$f"
  grep -q '^ENTRYPOINT \["/' "$f"
  grep -q 'Source of truth: formats/platform_support.yaml' "$f"
done

echo "docker runtime contract: OK"
