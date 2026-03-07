# Queue Integrity Protection v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/governance/observability_gap_registry.md`

## Назначение
Этот документ задаёт baseline защиты очередей, backlog и event-потоков от дублирования, зацикливания, бесконтрольного роста и скрытой потери порядка.

## Обязательные свойства
1. У каждого queue/backlog/spool path должен быть budget.
2. У каждого path должен быть anti-loop механизм.
3. Duplicate flood не должен quietly считаться нормальным трафиком.
4. При превышении budget система обязана перейти в контролируемый режим, а не продолжать бесконечно наращивать хвост.

## Минимальные предохранители
- per-source backlog cap;
- per-agent / per-tenant quota;
- duplicate detector;
- monotonic seq guard;
- anti-loop detector для replay / resend / bridge path;
- quarantine или dead-letter для неисправимых записей.

## Gap событие
- `observability_gap.queue_integrity_violation`
- evidence minimum:
  - `queue_name`
  - `source_id`
  - `violation_type`
  - `backlog_count`
  - `duplicate_count`
  - `trace_id`

## Что считается нарушением
- duplicate flood не фиксируется отдельным сигналом;
- replay превращается в цикл;
- backlog растёт без budget/gap/event;
- порядок и seq-consistency уже нарушены, но система выглядит "зелёной".

## Связанные runbooks
- `docs/runbooks/queue_integrity_violation.md`
- `docs/runbooks/spool_full.md`
- `docs/runbooks/ingest_overloaded.md`
