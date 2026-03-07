#!/usr/bin/env bash
set -euo pipefail
for f in docs/security/secure_sdlc_policy.md docs/security/branch_tag_policy.md docs/security/ci_pinning_policy.md docs/security/sast_policy.md docs/security/sca_policy.md docs/security/secrets_policy.md docs/security/sbom_policy.md docs/security/provenance_signing.md docs/security/dependency_update_policy.md docs/security/release_hardening.md .github/workflows/security_stage04.yml .github/workflows/release_stage04.yml .github/dependabot.yml scripts/ci/check_secure_sdlc_stage04.sh; do
  test -s "$f"
done
test -s docs/security/allowlist.gitleaks.toml
grep -q "clean build" docs/security/secure_sdlc_policy.md
grep -q "reproducible" docs/security/secure_sdlc_policy.md
grep -q "artifact hash" docs/security/secure_sdlc_policy.md
for c in "sdlc-gate" "sast" "sca" "license" "secrets"; do
  grep -q "$c" docs/security/branch_tag_policy.md
done
grep -q "commit SHA" docs/security/ci_pinning_policy.md
grep -q "@v" docs/security/ci_pinning_policy.md
grep -q "composite" docs/security/ci_pinning_policy.md
grep -q "semgrep" docs/security/sast_policy.md
grep -q "osv-scanner" docs/security/sca_policy.md
grep -q "licenses" docs/security/sca_policy.md
grep -q "gitleaks" docs/security/secrets_policy.md
grep -q "pull_request" docs/security/secrets_policy.md
grep -q "push" docs/security/secrets_policy.md
grep -q "allowlist.gitleaks.toml" docs/security/secrets_policy.md
if grep -q "placeholder" docs/security/allowlist.gitleaks.toml; then
  echo "gitleaks allowlist placeholder is forbidden"
  exit 1
fi
grep -q "useDefault = true" docs/security/allowlist.gitleaks.toml
grep -q "paths = \\[\\]" docs/security/allowlist.gitleaks.toml
grep -q "syft" docs/security/sbom_policy.md
grep -q "SPDX" docs/security/sbom_policy.md
grep -q "cosign" docs/security/provenance_signing.md
grep -q "OIDC" docs/security/provenance_signing.md
for a in "agent/dist/*" "ui/dist/*" "sbom.spdx.json" "checksums.txt"; do grep -q "$a" docs/security/provenance_signing.md; done
grep -q "provenance.attestation.json" docs/security/provenance_signing.md
grep -q "Dependabot" docs/security/dependency_update_policy.md
grep -q "PR-only" docs/security/dependency_update_policy.md
grep -q "sdlc-gate" docs/security/dependency_update_policy.md
grep -q "weekly" docs/security/dependency_update_policy.md
grep -q "auto-merge" docs/security/dependency_update_policy.md
grep -q 'package-ecosystem: "github-actions"' .github/dependabot.yml
grep -q 'package-ecosystem: "cargo"' .github/dependabot.yml
grep -q 'package-ecosystem: "npm"' .github/dependabot.yml
grep -q 'interval: "weekly"' .github/dependabot.yml
grep -q 'target-branch: "main"' .github/dependabot.yml
grep -q "provenance.attestation.json" .github/workflows/release_stage04.yml
grep -q "Verify provenance attestation payload" .github/workflows/release_stage04.yml
grep -q "gitleaks/gitleaks-action@" .github/workflows/security_stage04.yml
grep -q "GITLEAKS_CONFIG: docs/security/allowlist.gitleaks.toml" .github/workflows/security_stage04.yml
if grep -q "placeholder" .github/workflows/security_stage04.yml; then
  echo "security_stage04 workflow contains placeholder steps"
  exit 1
fi
grep -q "semgrep scan" .github/workflows/security_stage04.yml
grep -q "setuptools==80.9.0" .github/workflows/security_stage04.yml
grep -q "osv-scanner scan source --recursive --format json --output osv-report.json ." .github/workflows/security_stage04.yml
grep -q "cargo deny check licenses" .github/workflows/security_stage04.yml
grep -q "license-checker --production --summary" .github/workflows/security_stage04.yml
grep -q "actions/upload-artifact@" .github/workflows/security_stage04.yml
grep -q "semgrep-report.json" .github/workflows/security_stage04.yml
grep -q "osv-report.json" .github/workflows/security_stage04.yml
grep -q "license-summary.txt" .github/workflows/security_stage04.yml
grep -q "working-directory: browser" .github/workflows/security_stage04.yml
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
