# Stage33 Step6 NRAC Evaluation Report

- Date: 2026-03-06
- Test: `cargo test -p art-core critical_action_requires_nrac_and_blocks_on_high_regret -- --nocapture`
- Result: PASS

## Verified Rules
- Critical actions (`service.rollback`, `service.terminate`) are blocked when `x-action-nrac-regret` is missing.
- Critical actions are blocked when `x-action-nrac-regret` is above threshold (`CORE_NRAC_REGRET_THRESHOLD`, default `0.05`).
- Critical actions are allowed when regret is below threshold.

## Fixtures
- Deny (missing): `error=nrac_required`, `code=action_nrac_missing`
- Deny (high regret): `error=nrac_regret_exceeded`, `code=action_nrac_regret_exceeded`
- Allow (low regret): `accepted=true`, `nrac.status=accepted`
