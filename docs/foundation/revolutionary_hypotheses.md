# Revolutionary Hypotheses Backlog

Последняя актуализация: 2026-03-06
Статус: DRAFT

## Правило
Каждая гипотеза проходит как R&D-эксперимент и не становится mandatory до явного утверждения и критериев проверки.

## HYP-001 — Refutation Tournament Protocol (RTP)
- Hypothesis: состязательная проверка claim набором refuter-правил снижает false-positive решения.
- Why now: усиливает Evidence-first и снижает риск недоказуемых решений до action-стадии.
- Experiment design: refuter interface + tournament verdict (`passed`/`contested`) + trace артефактов опровержения.
- Success metrics: false-positive decision rate и reopen rate ниже baseline, без роста MTTR > 5%.
- Adoption gate: переход в mandatory только после PASS на контрольной выборке инцидентов в двух релизных циклах.

## HYP-002 — Live Runbook Compiler (LRC)
- Hypothesis: runbook, скомпилированный в исполняемые evidence-предусловия, снижает ошибки устаревших инструкций.
- Why now: runbook drift является частым источником неправильных действий при инцидентах.
- Experiment design: compile runbook -> condition graph -> runtime invalidation + suggested evidence patch.
- Success metrics: runbook-mismatch incidents и manual overrides ниже baseline, triage time уменьшается.
- Adoption gate: включение в mandatory после PASS в Stage31/33 e2e и подтверждённой стабильности на Linux production profile.

## HYP-003 — No-Regret Action Certificate (NRAC)
- Hypothesis: сертификат regret-bound перед execute снижает rollback и policy-violation rate.
- Why now: Action Studio переходит к более частой автоматизации и требует формализованной предоценки риска.
- Experiment design: regret estimator на исторических InvestigationDoc + human-readable certificate attach в preflight.
- Success metrics: rollback rate и policy-violation rate ниже baseline без деградации MTTR > 10%.
- Adoption gate: mandatory только после PASS stage33/stage34 suites и независимого replay-подтверждения.

## HYP-004 — Deterministic Incident Twin
- Hypothesis: инцидент можно воспроизводить из сырого потока + snapshot без расхождений между кластерами.
- Why now: ускоряет RCA и training без доступа к прод.
- Experiment design: replay sandbox + parity reports между prod snapshot и twin.
- Success metrics: replay mismatch rate = 0 для контрольного корпуса.
- Adoption gate: включение в Stage31/34 после PASS nightly replay 30 дней.

## HYP-005 — Proof-Carrying AI Claims
- Hypothesis: AI может генерировать только те claims, которые автоматически верифицируются через evidence_refs/proof_set.
- Why now: снижает юридический и операционный риск недоказуемых выводов.
- Experiment design: claim verifier middleware + negative tests на claims без evidence.
- Success metrics: 100% deny для claims без evidence, 0 bypass в e2e.
- Adoption gate: включение в Stage30/33 после PASS 2 последовательных релизных циклов.
