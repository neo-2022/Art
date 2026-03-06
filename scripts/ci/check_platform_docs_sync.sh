#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

RU_EN_PAIRS=(
  "docs/ops/platform-support.md:docs/en/ops/platform-support.md"
  "docs/security/fstec-certified-profile.md:docs/en/security/fstec-certified-profile.md"
)

base_ref="${GITHUB_BASE_REF:-main}"
if git rev-parse --verify "origin/${base_ref}" >/dev/null 2>&1; then
  base_commit="$(git merge-base HEAD "origin/${base_ref}")"
else
  base_commit="$(git rev-list --max-parents=0 HEAD | tail -n 1)"
fi
changed_files="$(git diff --name-only "${base_commit}...HEAD" 2>/dev/null || true)"

for pair in "${RU_EN_PAIRS[@]}"; do
  ru="${pair%%:*}"
  en="${pair##*:}"
  test -s "$ru"
  test -s "$en"
  grep -q "^## Source of truth" "$ru"
  grep -q "^## Source of truth" "$en"

  ru_changed=0
  en_changed=0
  grep -qx "$ru" <<<"$changed_files" && ru_changed=1 || true
  grep -qx "$en" <<<"$changed_files" && en_changed=1 || true

  if [[ "$ru_changed" -ne "$en_changed" ]]; then
    echo "RU/EN docs out of sync in commit range: $ru <-> $en"
    exit 1
  fi
done

echo "platform docs RU/EN sync gate: OK"
