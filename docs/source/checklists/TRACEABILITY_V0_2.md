# TRACEABILITY v0.2 (01..27 -> 28..38)

Последняя актуализация: 2026-03-06
Назначение: связать закрытые baseline этапы `01..27` с новой программой `28..38` и явно разделить reused baseline и новые требования.

## 1. Принципы трассировки
- `01..27` не отменяются и остаются baseline.
- `28..38` расширяют программу Incident OS без удаления уже принятых инвариантов.
- Новый этап может переиспользовать артефакты старых этапов только при явном указании reuse.

## 2. Mapping

| Baseline (01..27) | v0.2 Stage (28..38) | Reuse | Новые обязательства |
|---|---|---|---|
| 07, 08 | 28 (Console Foundation) | CI/docs discipline, contracts hygiene | monorepo apps+packages, ui-laws runtime gates |
| 08, 10, 14 | 29 (Event DNA Core v2) | ingest/snapshot/stream patterns | deterministic DNA canonicalization + formal model + property 1M + reference parity + v2 endpoints |
| 02, 09, 15 | 30 (Evidence/Claims/Dialogic) | privacy/audit discipline | evidence blocks + claim lifecycle + dialog schemas |
| 14, 15, 22 | 31 (Investigations-as-Code) | stream/action traces | versioned InvestigationDoc + fork/replay/compare |
| 15, 25 | 32 (Audit + Merkle verify) | audit append-only baseline | cryptographic proof verify in UI |
| 15, 23 | 33 (Secure Actions protocol) | RBAC/mode enforcement | preflight-first UX + policy-as-ui runtime |
| 14, 21, 22 | 34 (Perf/Load/Coverage ratchet) | load/chaos discipline | coverage ratchet + DNA perf budgets + 5% regression guard |
| 10, 14 | 35 (Spatial Store + 3D readiness) | stream events + UI laws | typed spatial store + deterministic layout pipeline |
| 01, 23, 25 | 36 (SaaS readiness architecture) | governance/compliance baseline | tenant model + control/data plane contracts |
| 16, 22, 23 | 37 (Linux prod hardening Tier A/B) | panel0 linux readiness | console linux hardening + rollout/rollback + DNA canary divergence control |
| 00, 07 | 38 (Stage ladder enforcement) | process/ci baseline | CI-enforced stage order + status integrity guard |

## 3. Baseline already covering v0.2
- Stage16 уже покрывает embedded Panel0 fallback, backlog и runtime docs-gates.
- Stage15 уже покрывает RBAC и append-only аудит на API baseline.
- Stage22 уже задаёт E2E/chaos/perf дисциплину и nightly smoke.

## 4. Baseline not covering v0.2 (new work)
- Нет production-ready `apps/console-web` и `packages/*` структуры.
- Нет `/api/v2/*` DNA/Evidence контрактов и runtime endpoints.
- Нет enforceable UI-laws runtime checks в Console foundation.
- Нет v0.2 coverage ratchet gate.

## 5. Closing rule
Закрытие `CHECKLIST_28..38` допускается только при наличии:
1. PASS тестов/гейтов конкретного этапа.
2. Артефактов проверки в репозитории.
3. Отметки в `CHECKLIST_00_MASTER_ART_REGART.md`.
4. Актуализации `docs/source/risk_register_v0_2.md` для затронутых рисков.
