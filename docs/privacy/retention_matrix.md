# Матрица Хранения Данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/privacy/data_classification.md`

## Матрица

| Тип данных | Retention | Storage | Deletion | Owner component |
|---|---|---|---|---|
| events | 30 days | sqlite | hard delete | core/storage |
| incidents | 180 days | sqlite | hard delete | core/incidents |
| audit | 365 days | sqlite | hard delete | core/audit |
| attachments | 30 days | blob/local | hard delete | core/attachments |

## Правило

Ни одна категория данных не должна храниться дольше, чем разрешено действующей policy и profile enforcement.
