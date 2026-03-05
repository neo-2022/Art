# Runbook: agent_spool_near_full

## mitigations
1. Проверить скорость flush в Core.
2. Снизить входящий поток или увеличить capacity.
3. Проверить отсутствие `spool_full` событий.

## verification
- `spool_used_bytes / spool_capacity_bytes < 0.90`;
- incident `agent.spool_near_full` закрыт.
