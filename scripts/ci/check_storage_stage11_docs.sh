#!/usr/bin/env bash
set -euo pipefail
for f in docs/core/storage.md docs/ops/backup_restore_sqlite.md docs/ops/storage_corruption_runbook.md docs/ops/vacuum_schedule.md docs/ops/storage.md; do
  test -s "$f"
done
grep -q "HTTP 503" docs/ops/storage_corruption_runbook.md
grep -q "retry_after_ms" docs/ops/storage_corruption_runbook.md
grep -q "read_only" docs/ops/storage_corruption_runbook.md
grep -Eq "Sunday|воскресенье" docs/ops/vacuum_schedule.md
grep -q "03:30" docs/ops/vacuum_schedule.md
grep -q "integrity check" docs/ops/backup_restore_sqlite.md
echo "stage11 docs gate: OK"
