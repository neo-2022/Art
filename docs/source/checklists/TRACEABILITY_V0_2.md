# TRACEABILITY v0.2 (01..27 -> 28..45)

Последняя актуализация: 2026-03-06
Назначение: связать закрытые baseline этапы `01..27` с новой программой `28..45` и явно разделить reused baseline и новые требования, включая continuation backlog уникальных approved-концепций.

## 1. Принципы трассировки
Обязательный baseline marker для legacy CI/gates: `01..27 -> 28..38`.
Continuation expansion marker: `01..27 -> 28..45`.

- `01..27` не отменяются и остаются baseline.
- `28..38` расширяют программу Incident OS без удаления уже принятых инвариантов.
- Новый этап может переиспользовать артефакты старых этапов только при явном указании reuse.

## 2. Mapping для 28..38

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


## 2A. Continuation mapping для 39..45

| Continuation stage | Источник замысла | Что закрывает | Почему это обязательно |
|---|---|---|---|
| 39 | AI engineering operating model | role map, review split, lessons learned, truthfulness gate | без этого большая программа снова скатывается в формальные отметки и потерю замысла |
| 40 | Art visual language + showcase layer | клиентский и брендовый product layer | проект должен быть не только инженерно корректным, но и демонстрируемым без разрыва с реальностью |
| 41 | advanced automation backlog | AST UI laws, self-healing test/doc maintenance | ручная дисциплина больше не масштабируется на весь контур Art |
| 42 | revolutionary hypotheses / tech radar | proof completeness, drift radar, proof-carrying AI | ключевые differentiators должны стать частью продукта, а не остаться в backlog |
| 43 | revolutionary hypotheses / secure actions | counterfactual simulation, mature NRAC, sandbox extensibility | actions должны быть не только безопасными, но и интеллектуально ограниченными до execute |
| 44 | investigations + audit roadmap | reproducible incident capsule, deterministic twin | воспроизводимость инцидентов должна быть переносимой и проверяемой end-to-end |
| 45 | advanced automation + platform/deep forensics | eBPF evidence linking, graph-backed exploration | forensic и relationship navigation — часть заявленной уникальности продукта |

## 2B. Сквозная интеграция approved-концепций в ранние этапы 01..38

Continuation stages `39..45` не считаются первым местом появления approved-концепций. Ниже зафиксирован обязательный ранний integration path, который должен учитываться уже при прохождении базовой программы.

| Approved-концепция | Ранний integration path | Где обязана начать влиять | Что должно появиться до stage39+ |
|---|---|---|---|
| AI engineering operating model | 01, 04, 07, 24, 38 | governance, review, release, truthfulness | role split, review discipline, evidence-aware status control |
| Product showcase / visual language | 28, 35, 37 | foundation UI, flow/spatial, linux runtime | design laws, showcase-safe degradation, perf-safe presentation policy |
| AST/static UI laws | 28, 30, 34 | console foundation, truth modes, perf discipline | UI law inventory, negative scenarios, impact-aware checks |
| Proof Completeness Score | 30, 31, 34 | evidence/claims, investigations, anti-overload UX | claim quality model, UI space for score/explanation, perf budget |
| DNA Drift Radar | 29, 34, 37 | DNA core, perf/load, canary/replay | deterministic drift corpus, replay hooks, divergence policy |
| Proof-Carrying AI Claims | 30, 33, 39 | claims/actions/governance | ban on AI claim without evidence, negative gates, audit trail |
| Counterfactual Action Simulator | 31, 33, 34 | investigations, secure actions, perf budget | preflight attachment points, no-side-effect path, perf constraints |
| Mature NRAC | 33, 37 | secure actions, release/hardening | certificate path, policy exception handling, runtime gate planning |
| Reproducible Incident Capsule | 31, 32, 34 | investigations, audit, replay regression | versioning hooks, proof attachment, replay evidence expectations |
| Deterministic Incident Twin | 29, 31, 34, 37 | DNA determinism, replay, canary | parity/replay baseline, drift-safe corpus, divergence alerts |
| eBPF evidence linking | 37, 26, 45 | Linux/RU/policy boundary | privacy/policy constraints, kernel/profile contracts, safe opt-in model |
| Graph-backed exploration | 35, 40, 45 | spatial/flow/showcase | inspectability laws, deterministic navigation, derived-store boundaries |
| Wasm sandbox for actions | 33, 37 | secure actions, linux hardening | sandbox boundary assumptions, audit hooks, capability policy path |
| Self-healing tests/docs | 07, 08, 28, 30, 38 | CI/contracts/console/process | impact-report discipline, generated-example policy, no-silent rewrite rule |
| Полный сбор доступных сигналов и внешних систем | 09, 18, 19, 20 | telemetry/agent/packs/regart | source coverage matrix, ingress mechanisms, external system knowledge in packs |
| Машиночитаемый РФ нормативный контур | 25, 26, 37 | compliance/RU/platform | `ru_regulatory_scope.yaml`, regulatory evidence-pack, certified-ready boundary |
| Layer E / Agent Workspace | 28, 30, 31, 33, 39 | console foundation / dialog / investigations / agent governance | evidence-anchored agent workspace, proposal queue, actor provenance, no silent execution |

## 2C. Сквозная интеграция deployment/transport контура агента

| Тема | Ранние этапы | Что должно появиться до финализации |
|---|---|---|
| Multi-site / WAN deployment Art Agent | 18, 23, 37 | source-of-truth topology doc, ops runbook, Linux production boundary |
| Segmented / air-gapped agent delivery | 18, 23, 26, 37 | spool/replay law, approved relay/export path, RU profile constraints, platform hardening |
| Agent install models (`systemd` / `container` / `DaemonSet` / offline package) | 18, 23, 37 | machine-readable and runbook-level install/deploy guidance without distro-specific app logic |

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

## 6. Foundation continuation set (post-stage38 governance backlog)
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md` — единый историко-концептуальный корпус проекта.
- `docs/foundation/revolutionary_hypotheses.md` — experimental/approved backlog уникальных гипотез продукта.
- `docs/foundation/frontier_tech_radar.md` — technology radar с checklist mapping.
- `docs/foundation/lens_audit_report.md` — governance-аудит линз и gaps.
- `docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md` — operating model AI-команды, связанный с stage28/stage29/stage38.
- `docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md` — backlog глубокой автоматизации, привязанный к stages 28/29/30/31/33/34/35/38.
- `docs/portal/ART_VISUAL_LANGUAGE.md` — брендово-операционный визуальный слой, привязанный к stages 28 и 35.

Эти документы не открывают новый этап сами по себе, но задают обязательный continuation backlog для следующего цикла развития после текущей программы 28..38.
