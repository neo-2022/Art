# Operational Debt Register (Linux Tier A/B)

Последняя актуализация: 2026-03-06
Статус: ACTIVE

## Правило
- В реестр попадают только production-risk долги.
- Каждый долг обязан иметь owner, due_date, mitigation plan и текущий статус.
- Просроченный `critical` долг без mitigation блокирует rollout.

## Поля записи
- debt_id
- title
- risk_level (`critical|high|medium|low`)
- owner
- created_at
- due_date
- affected_components
- mitigation
- status (`open|in_progress|closed`)
- evidence_ref

## Записи
| debt_id | title | risk_level | owner | created_at | due_date | affected_components | mitigation | status | evidence_ref |
|---|---|---|---|---|---|---|---|---|---|
| OD-001 | Stage37 template debt placeholder | medium | @neo-2022 | 2026-03-06 | 2026-04-06 | tier-b-console | заполнить реальными production debt после первых canary прогонов | open | docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md |
