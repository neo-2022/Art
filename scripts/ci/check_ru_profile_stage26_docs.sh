#!/usr/bin/env bash
set -euo pipefail
for f in docs/ru/profile_ru.md docs/ru/access_audit.md docs/ru/export.md docs/ru/airgapped_install.md docs/runbooks/cross_border_export_blocked.md; do
  test -s "$f"
done
grep -q "field_path" docs/ru/profile_ru.md
grep -q "store_ru_only" docs/ru/profile_ru.md
grep -q "GET /api/v1/incidents/{id}" docs/ru/access_audit.md
grep -q "incident_id" docs/ru/access_audit.md
grep -q "client_ip" docs/ru/access_audit.md
grep -q "user_agent" docs/ru/access_audit.md
grep -q "effective_profile_id=ru" docs/ru/export.md
grep -q "blocked" docs/ru/export.md
grep -q "cosign" docs/ru/airgapped_install.md
grep -q "verify" docs/ru/airgapped_install.md
grep -q "checksums" docs/ru/airgapped_install.md
grep -q "mitigations" docs/runbooks/cross_border_export_blocked.md
grep -q "verification" docs/runbooks/cross_border_export_blocked.md
grep -q "cross_border_export_blocked" docs/governance/observability_gap_registry.md
grep -q "effective_profile_id" scripts/export_audit_pack.sh
grep -q "RU_EXPORT_ALLOWLIST_ROOT" scripts/export_audit_pack.sh
echo "stage26 docs gate: OK"
