# Runbook: e2e environment failed

## mitigations
1. Проверить старт Core/Agent.
2. Проверить порт/сеть и доступность health/snapshot.
3. Перезапустить runner и повторить setup.

## verification
- В snapshot/stream появляется `observability_gap.e2e_environment_failed`.
- Evidence содержит `component`, `reason`, `stage`, `trace_id`.
