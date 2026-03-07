# Революционные Гипотезы Art

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/foundation/frontier_tech_radar.md`

Последняя актуализация: 2026-03-06
Статус: ACTIVE BACKLOG

## Назначение
Этот документ фиксирует экспериментальные и перспективные гипотезы проекта. Он не объявляет их автоматически mandatory. Каждая гипотеза должна иметь:
- понятный смысл;
- ожидаемую пользу;
- критерий успеха;
- checklist mapping;
- adoption gate.

## Правило
Каждая гипотеза проходит как R&D-эксперимент и не становится mandatory до явного утверждения, проверки и evidence.

## Шкала статусов
- `Implemented experimental` — гипотеза уже частично внедрена как экспериментальный контур.
- `Approved backlog` — гипотеза утверждена как ценная, но ещё не переведена в полный execution-track.
- `Deferred` — гипотеза признана полезной, но её внедрение отложено.

## HYP-001 — Refutation Tournament Protocol (RTP)
Статус: Implemented experimental
Checklist mapping:
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- состязательная проверка claim набором refuter-правил снижает false-positive решения.
Почему это важно:
- система не просто подтверждает hypothesis, а пытается её опровергнуть.
Текущий след в проекте:
- UI law и тесты для RTP verdict.
- KPI regression track в stage34.
Success metrics:
- false-positive decision rate и reopen rate ниже baseline, без роста MTTR > 5%.
Adoption gate:
- переход в mandatory только после PASS на контрольной выборке инцидентов в двух релизных циклах.

## HYP-002 — Live Runbook Compiler (LRC)
Статус: Implemented experimental
Checklist mapping:
- `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- runbook, скомпилированный в исполняемые evidence-предусловия, снижает ошибки устаревших инструкций.
Почему это важно:
- runbook drift является частым источником неправильных действий при инцидентах.
Текущий след в проекте:
- compiler test path и mismatch reports.
Success metrics:
- runbook-mismatch incidents и manual overrides ниже baseline, triage time уменьшается.
Adoption gate:
- включение в mandatory после PASS в Stage31/33 e2e и подтверждённой стабильности на Linux production profile.

## HYP-003 — No-Regret Action Certificate (NRAC)
Статус: Implemented experimental
Checklist mapping:
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- сертификат regret-bound перед execute снижает rollback и policy-violation rate.
Почему это важно:
- Action Studio движется в сторону формализованной автоматизации и требует более строгой предоценки риска.
Текущий след в проекте:
- allow/deny fixtures, evaluation report, policy threshold enforcement.
Success metrics:
- rollback rate и policy-violation rate ниже baseline без деградации MTTR > 10%.
Adoption gate:
- mandatory только после PASS stage33/stage34 suites и независимого replay-подтверждения.

## HYP-004 — Deterministic Incident Twin
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- инцидент можно воспроизводить из сырого потока + snapshot без расхождений между кластерами.
Почему это важно:
- ускоряет RCA, обучение и безопасный replay без доступа к production.
Success metrics:
- replay mismatch rate = 0 для контрольного корпуса.
Adoption gate:
- включение после PASS nightly replay 30 дней.

## HYP-005 — Proof-Carrying AI Claims
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
Смысл:
- AI может генерировать только те claims, которые автоматически верифицируются через evidence_refs/proof_set.
Почему это важно:
- снижает юридический и операционный риск недоказуемых выводов.
Success metrics:
- 100% deny для claims без evidence, 0 bypass в e2e.
Adoption gate:
- включение после PASS двух последовательных релизных циклов.

## HYP-006 — Proof Completeness Score
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- у каждого claim появляется числовая оценка полноты доказательной базы.
Почему это важно:
- помогает обычному пользователю быстро понимать, насколько утверждение хорошо подтверждено.
Success metrics:
- снижение ложных confident decisions и улучшение explainability acceptance.
Adoption gate:
- mandatory только после определения формулы, UX-validation и regression-safe rollout.

## HYP-007 — DNA Drift Radar
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- система замечает появление новых классов проблем до того, как они разрастаются в крупный инцидент.
Почему это важно:
- переводит Event DNA из реактивной навигации в раннее предупреждение.
Success metrics:
- lead-time advantage до инцидента и контролируемый false-positive rate.
Adoption gate:
- только после определённой метрики drift и PASS на canary corpus.

## HYP-008 — Counterfactual Action Simulator
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
Смысл:
- перед action execute система показывает вероятные последствия и альтернативы.
Почему это важно:
- уменьшает число необдуманных действий и усиливает Action Studio.
Success metrics:
- ниже rollback rate, выше operator confidence, без MTTR regression beyond policy.
Adoption gate:
- только после исторической базы, replay accuracy и bounded-side-effects policy.

## HYP-009 — Reproducible Incident Capsule
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
- `CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md`
Смысл:
- инцидент собирается в единый переносимый, проверяемый и криптографически связанный слепок.
Почему это важно:
- резко усиливает audit/compliance/training и передачу знаний между командами.
Success metrics:
- reproducible replay parity и human-verifiable capsule export/import.
Adoption gate:
- после утверждения capsule format, verify chain и replay toolchain.

## HYP-010 — Autonomic UX Governor
Статус: Approved backlog
Checklist mapping:
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
- `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`
Смысл:
- интерфейс сам удерживает usability и p95 latency в рамках бюджета.
Почему это важно:
- защищает продукт от визуальной деградации на слабых GPU и перегруженных окружениях.
Success metrics:
- меньше perf-complaints, стабильный p95 budget, предсказуемый fallback behavior.
Adoption gate:
- после telemetry loop, explicit downgrade ladder и UX validation.
