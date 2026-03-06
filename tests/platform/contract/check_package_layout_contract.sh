#!/usr/bin/env bash
set -euo pipefail

# Source of truth: formats/platform_support.yaml

for f in \
  packaging/deb/art-core/DEBIAN/control \
  packaging/deb/art-agent/DEBIAN/control \
  packaging/rpm/art-core/art-core.spec \
  packaging/rpm/art-agent/art-agent.spec \
  systemd/art-vacuum.service
  do
  test -s "$f"
done

grep -q '^Package: art-core' packaging/deb/art-core/DEBIAN/control
grep -q '^Package: art-agent' packaging/deb/art-agent/DEBIAN/control
grep -q '^Name:\s*art-core' packaging/rpm/art-core/art-core.spec
grep -q '^Name:\s*art-agent' packaging/rpm/art-agent/art-agent.spec
grep -q '^\[Unit\]' systemd/art-vacuum.service

echo "platform package layout contract: OK"
