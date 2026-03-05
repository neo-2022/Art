# Self-observability

Фиксированный список internal incidents:
1. `core.high_latency`
   - критерий: p95 `ingest_latency_ms` > 500 в окне 5 минут
   - severity: SEV2+
   - action_ref: `docs/runbooks/core_high_latency.md`
2. `agent.spool_near_full`
   - критерий: `spool_used_bytes / spool_capacity_bytes >= 0.90` в окне 1 минута
   - severity: SEV2+
   - action_ref: `docs/runbooks/agent_spool_near_full.md`
3. `dlq_non_empty`
   - критерий: `dlq_size > 0` в окне 10 минут
   - severity: SEV3+
   - action_ref: `docs/runbooks/dlq_non_empty.md`
4. `source_stale`
   - критерий: наличие `observability_gap.source_stale` (threshold 10 минут)
   - severity: SEV2+
   - action_ref: `docs/runbooks/source_stale.md`
