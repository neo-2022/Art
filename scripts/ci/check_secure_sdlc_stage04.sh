#!/usr/bin/env bash
set -euo pipefail
for f in docs/security/secure_sdlc_policy.md docs/security/branch_tag_policy.md docs/security/ci_pinning_policy.md docs/security/sast_policy.md docs/security/sca_policy.md docs/security/secrets_policy.md docs/security/sbom_policy.md docs/security/provenance_signing.md docs/security/dependency_update_policy.md docs/security/release_hardening.md .github/workflows/security_stage04.yml .github/workflows/release_stage04.yml scripts/ci/check_secure_sdlc_stage04.sh; do
  test -s "$f"
done
grep -q "clean build" docs/security/secure_sdlc_policy.md
grep -q "reproducible" docs/security/secure_sdlc_policy.md
grep -q "artifact hash" docs/security/secure_sdlc_policy.md
for c in "security-stage04 / sdlc-gate" "security-stage04 / sast" "security-stage04 / sca" "security-stage04 / license" "security-stage04 / secrets"; do
  grep -q "$c" docs/security/branch_tag_policy.md
done
grep -q "commit SHA" docs/security/ci_pinning_policy.md
grep -q "@v" docs/security/ci_pinning_policy.md
grep -q "composite" docs/security/ci_pinning_policy.md
grep -q "semgrep" docs/security/sast_policy.md
grep -q "osv-scanner" docs/security/sca_policy.md
grep -q "licenses" docs/security/sca_policy.md
grep -q "gitleaks" docs/security/secrets_policy.md
grep -q "syft" docs/security/sbom_policy.md
grep -q "SPDX" docs/security/sbom_policy.md
grep -q "cosign" docs/security/provenance_signing.md
grep -q "OIDC" docs/security/provenance_signing.md
for a in "agent/dist/*" "ui/dist/*" "sbom.spdx.json" "checksums.txt"; do grep -q "$a" docs/security/provenance_signing.md; done
# pinning checks for workflows and local actions
if grep -RInE 'uses:\s+[^ ]+@(v|main|master)' .github/workflows/*.yml; then exit 1; fi
if grep -RInE 'uses:\s+docker://' .github/workflows/*.yml; then exit 1; fi
# allow local actions or full SHA pin
if grep -RInE 'uses:\s+[^ ]+@[^0-9a-f\.][^ ]*' .github/workflows/*.yml; then :; fi
for wf in .github/workflows/*.yml; do
  while IFS= read -r line; do
    u=$(echo "$line" | sed -E 's/.*uses:\s*//')
    case "$u" in
      ./.github/actions/*) ;;
      */*@????????????????????????????????????????) ;;
      *) echo "invalid uses format in $wf: $u"; exit 1;;
    esac
  done < <(grep -E '^[[:space:]]*uses:' "$wf")
done
if [ -d .github/actions ]; then
  while IFS= read -r f; do
    if grep -E 'uses:\s+[^ ]+@(v|main|master)' "$f"; then exit 1; fi
    if grep -E 'uses:\s+docker://' "$f"; then exit 1; fi
    while IFS= read -r line; do
      u=$(echo "$line" | sed -E 's/.*uses:\s*//')
      case "$u" in
        ./.github/actions/*) ;;
        */*@????????????????????????????????????????) ;;
        *) echo "invalid uses format in $f: $u"; exit 1;;
      esac
    done < <(grep -E '^[[:space:]]*uses:' "$f")
  done < <(find .github/actions -type f -name action.yml)
fi
echo "stage04 sdlc gate: OK"
