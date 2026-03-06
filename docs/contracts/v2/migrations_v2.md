# API/Data v2 Migration and Rollback

Последняя актуализация: 2026-03-06

## Forward
1. Create v2 data structures (`events_v2`, `dna_clusters`, `evidence_blocks`).
2. Deploy code with dual-read compatibility (`v1` + `v2`).
3. Enable v2 ingest/snapshot/stream endpoints.
4. Validate deterministic dna signatures on canary.

## Rollback
1. Disable v2 ingest entrypoint.
2. Keep v2 data immutable for forensics.
3. Route Console to v1 read-path.
4. Verify no data loss in v1 snapshot/stream.

## Verification
- v2 health checks pass
- deterministic tests pass
- rollback dry-run documented
- observability_gap.v2_migration_failed absent

## Dual-write verification
1. During migration window write events to v1 and v2 paths.
2. Compute comparable hashes for v1/v2 payloads by trace_id.
3. Apply delivery lag normalization:
   - `delivery_lag_grace_window` фиксируется в rollout-профиле (default: `10s` для Linux prod);
   - records inside `delivery_lag_grace_window` are marked `pending`;
   - only matured records participate in mismatch calculation.
4. Block rollout if normalized mismatch rate > 0.
5. Emit `observability_gap.api_dual_write_mismatch` on any matured mismatch.

### Lag profile matrix (verification)
1. `delivery_lag_grace_window=5s`: проверка fast-path профиля, повышенный риск ложных mismatch.
2. `delivery_lag_grace_window=10s`: базовый Linux production профиль.
3. `delivery_lag_grace_window=15s`: профиль с повышенной репликационной задержкой.
4. Для каждого профиля обязательны: pending/matured разметка, normalized mismatch calculation, rollback decision.

## v1 sunset criteria
1. Minimum support window: 2 release cycles after v2 GA.
2. v1 traffic share below agreed threshold for 30 days.
3. Zero `api_dual_write_mismatch` incidents in final verification window.
4. Explicit deprecation approval and rollback plan archived before disable.
