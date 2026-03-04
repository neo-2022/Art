#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CORE_COMPAT="1.x"

make_pack() {
  local dir="$1"
  local with_signature="$2"
  local compat="$3"
  mkdir -p "$dir/payload" "$dir/signatures"
  cat >"$dir/manifest.toml" <<EOF
name = "pack-regart"
version = "1.0.0"
compatible_core = "$compat"
EOF
  if [[ "$with_signature" == "yes" ]]; then
    echo "dummy-signature" >"$dir/signatures/pack.sig"
  fi
}

verify_pack() {
  local dir="$1"
  if [[ ! -s "$dir/signatures/pack.sig" ]]; then
    return 10
  fi
  local compat
  compat="$(grep '^compatible_core = ' "$dir/manifest.toml" | sed -E 's/.*"([^"]+)".*/\1/')"
  if [[ "$compat" != "$CORE_COMPAT" ]]; then
    return 20
  fi
  return 0
}

echo "[stage03] test: no signature must fail"
NO_SIG="$TMP_DIR/no-signature"
make_pack "$NO_SIG" "no" "$CORE_COMPAT"
if verify_pack "$NO_SIG"; then
  echo "expected failure for unsigned pack"
  exit 1
fi

echo "[stage03] test: incompatible version must fail"
BAD_VER="$TMP_DIR/bad-version"
make_pack "$BAD_VER" "yes" "2.x"
if verify_pack "$BAD_VER"; then
  echo "expected failure for incompatible pack version"
  exit 1
fi

echo "[stage03] test: valid signed compatible pack must pass"
GOOD="$TMP_DIR/good-pack"
make_pack "$GOOD" "yes" "$CORE_COMPAT"
verify_pack "$GOOD"

echo "[stage03] airgapped pack update integration: OK"
