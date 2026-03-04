#!/usr/bin/env bash
set -euo pipefail

required=(
  docs/privacy/data_classification.md
  docs/privacy/pii_surface.md
  docs/privacy/data_minimization_policy.md
  docs/privacy/redaction_policy.md
  docs/privacy/retention_matrix.md
  docs/privacy/dsr_process.md
  docs/privacy/attachments_security.md
  docs/privacy/access_control_policy.md
  docs/privacy/encryption_policy.md
  docs/privacy/regional_profiles.md
  docs/privacy/test_matrix.md
  scripts/ci/check_privacy_stage02.sh
)

for f in "${required[@]}"; do
  test -s "$f"
done

grep -q "privacy.redaction_applied" docs/privacy/redaction_policy.md
grep -q "configurable rules" docs/privacy/redaction_policy.md
grep -q "observability_gap.redaction_failed" docs/privacy/redaction_policy.md
for key in events incidents audit attachments; do
  grep -q "$key" docs/privacy/retention_matrix.md
done
for key in MIME "magic bytes" "max size" "sanitize filename"; do
  grep -q "$key" docs/privacy/attachments_security.md
done
for key in RawEvent Incident AuditEntry AttachmentMeta; do
  grep -q "$key" docs/privacy/pii_surface.md
done

echo "privacy stage02 gate: OK"
