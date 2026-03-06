# Stage35 Guardrail Policy Report

- Policy: advanced flow mode is allowed only while perf/SLO budgets are healthy.
- Trigger: `p95_ms > budget_ms` or `error_count > 0`.
- Action: auto-downgrade to `read-only`.
- Verification:
  - local-stores integration test `advanced flow guardrail auto-downgrades to read-only on perf breach` PASS.
  - CI gate `stage35-flow-perf-2d-gate` PASS and confirms watchdog activation.
