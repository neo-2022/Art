# RISK REGISTER v0.2 (Program 28..38)

Последняя актуализация: 2026-03-06
Статус: ACTIVE

## Цель
Зафиксировать принятые риски программы v0.2, обязательные контрмеры, CI-gates, и release-blocker условия.

## Реестр

| ID | Риск | Вероятность | Влияние | Контрмеры (обязательно) | Checklist | CI gate | observability_gap | Release blocker |
|---|---|---|---|---|---|---|---|---|
| R1 | Эрозия архитектурных границ монорепо | Высокая | Критическое | Жёсткий boundary-enforcer, запрет cross-import, метрика forbidden-import-count = 0 | 28 | workspace-boundary-check | observability_gap.console_workspace_boundary_violation | forbidden-import-count > 0 |
| R2 | Конфликт v1/v2 API и миграция | Средняя | Высокое | Разделение api_v1/api_v2, dual-write verifier, schema-compat tests, deprecation plan | 29 | stage29-dna-tests | observability_gap.api_dual_write_mismatch | normalized mismatch rate > 0 (after delivery-lag grace window) |
| R3 | Неполные/устаревшие UI laws | Средняя | Среднее | Static lint + runtime sampling checks, law test generation, law semver policy | 30 | stage30-evidence-claims-tests, console-test | observability_gap.ui_law_violation | critical UI-law violation count > 0 |
| R5 | Сложность отладки DNA и трассировки решений | Высокая | Высокое | DNA decision trace, replay/time-travel checks, anomaly diagnostics | 29,31 | stage29-dna-assurance-gate | observability_gap.dna_traceability_gap | trace unavailable for critical incident |
| R8 | Узкие места local-stores | Средняя | Среднее | IndexedDB index budgets, worker offload, incremental indexing, store perf profiling | 34 | stage34-perf-load-tests | observability_gap.local_store_latency_exceeded | p95 local-store latency > budget |
| R9 | Privacy/compliance риски evidence | Низкая->Высокая в прод | Критическое | privacy-by-design, redaction enforcement, evidence access audit, request-driven anonymization flow | 30,36,37 | stage30-evidence-claims-tests, stage36-saas-architecture-gate, stage37-linux-hardening-gate | observability_gap.evidence_privacy_violation | unauthorized evidence access > 0 |
| R10 | Недооценка сложности Spatial/3D | Высокая | Среднее | ранний прототип, MVP scope lock, feature-flag fallback, weak-GPU perf tests | 35 | stage35-spatial-readiness-tests | observability_gap.spatial_index_degraded | picking p95 > threshold |
| R11 | Инновационные треки RTP/LRC/NRAC ухудшают базовые SLO | Средняя | Высокое | feature flags, KPI baseline/ratchet, Linux canary rollout, auto-disable on regression | 30,31,33,34,37 | stage30-evidence-claims-tests, stage31-investigation-doc-tests, stage33-secure-actions-tests, stage34-perf-load-tests, stage37-linux-hardening-gate | observability_gap.innovation_experiment_regression | KPI regression beyond policy threshold |
| R12 | Ошибочная маркировка Truth Modes (fact/prediction drift) | Средняя | Высокое | truth-mode contract checks, observed->evidence invariant, UI badge laws, regression tests | 30,31 | stage30-truth-modes-tests, stage31-investigation-library-tests | observability_gap.truth_mode_misuse | observed without evidence refs > 0 |
| R13 | Визуальная перегрузка Flow Mode снижает операционную управляемость | Средняя | Высокое | adaptive UX policy, perf watchdog, auto-downgrade to read-only, inspectability tests | 34,35,37 | stage35-flow-inspectability-tests, stage35-flow-snapshot-replay-tests, stage35-flow-perf-2d-gate, stage37-linux-hardening-gate | observability_gap.flow_visual_overload | flow p95 > budget without auto-downgrade |
| R14 | Internet-facing ingress остаётся без perimeter shield и abusive traffic isolation | Средняя | Критическое | front-door shield, per-IP/per-tenant limits, DDoS observability, release blockers, hostile ingress tests | 12,24,36,37,45 | stage12-docs-gate, stage24-docs-gate, stage36-saas-architecture-gate, stage37-linux-hardening-gate, stage45-forensic-graph-gate | observability_gap.ddos_suspected, observability_gap.ingress_shield_degraded | internet-exposed profile without shield baseline or hostile ingress evidence |

## Правила принятия риска
1. Риск считается под контролем только при PASS всех связанных CI-gates.
2. Любой Release blocker из таблицы немедленно останавливает rollout.
3. Изменение контрмер требует обновления checklist + runbook + registry.

## Зафиксированные policy-решения (2026-03-06)
1. Dual-write blocker: строго `normalized mismatch rate > 0` без допусков.
   - `mismatch` считается только для trace_id, у которых истёк `delivery_lag_grace_window` (default `10s` для Linux prod).
   - записи в пределах допустимой задержки доставки считаются `pending`, не `mismatch`.
2. Evidence retention/anonymization SLA:
   - оперативные данные evidence: 30 дней.
   - evidence инцидентов: 90 дней.
   - audit/compliance evidence: 365+ дней.
   - при переходе на долгий срок хранения PII автоматически анонимизируется.
   - request-driven anonymization/removal: не позднее 72 часов.
3. Weak-GPU профиль:
   - целевой минимум: Intel UHD 620 класс и типовой VM GPU.
   - целевой p95 latency < 50 ms в weak-gpu профиле.
   - при выходе за бюджет включается авто-деградация качества (LOD + упрощённая графика).
