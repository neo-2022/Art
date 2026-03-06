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
grep -q "DO записи в AuditEntry" docs/privacy/redaction_policy.md || grep -q "ДО записи в AuditEntry" docs/privacy/redaction_policy.md
grep -q "config/privacy/redaction_rules.yaml" docs/privacy/redaction_policy.md
for key in events incidents audit attachments; do
  grep -q "$key" docs/privacy/retention_matrix.md
done
grep -q "raw archive" docs/privacy/retention_matrix.md
for key in MIME "magic bytes" "max size" "sanitize filename"; do
  grep -q "$key" docs/privacy/attachments_security.md
done
grep -q "XSS" docs/privacy/attachments_security.md
for key in RawEvent Incident AuditEntry AttachmentMeta; do
  grep -q "$key" docs/privacy/pii_surface.md
done
grep -q "no HTTP bodies by default" docs/privacy/data_minimization_policy.md
grep -q "headers вне allowlist запрещены к записи" docs/privacy/data_minimization_policy.md
grep -q "cookies запрещены к записи" docs/privacy/data_minimization_policy.md
grep -q "user_id" docs/privacy/dsr_process.md
grep -q "external_id" docs/privacy/dsr_process.md
grep -q "AuditEntry append-only" docs/privacy/dsr_process.md
grep -q "public by default" docs/privacy/access_control_policy.md
grep -q "attachment bytes не пишутся в логи" docs/privacy/access_control_policy.md
grep -q "TLS обязателен in-transit" docs/privacy/encryption_policy.md
grep -q "90 days" docs/privacy/encryption_policy.md
grep -q "effective_profile_id" docs/privacy/regional_profiles.md
grep -q "default profile" docs/privacy/regional_profiles.md
grep -q "privacy.redaction_applied" docs/privacy/test_matrix.md
grep -q "XSS blocked" docs/privacy/test_matrix.md

echo "privacy stage02 gate: OK"
