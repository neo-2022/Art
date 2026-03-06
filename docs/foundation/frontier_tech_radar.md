# Frontier Tech Radar (Art / Console)

Последняя актуализация: 2026-03-06
Статус: DISCUSSION

## Назначение
Фиксировать перспективные технологии и их готовность к применению в продукте без нарушения обязательных Primary-инвариантов.

## Кольца радара
- Adopt: можно применять в production-контуре.
- Trial: можно запускать контролируемые эксперименты.
- Assess: требуется исследование и прототип.
- Hold: использовать запрещено в текущем контуре.

## Radar
| Topic | Ring | Why | Entry Criteria | Exit Criteria |
|---|---|---|---|---|
| Refutation Tournament Protocol (RTP) | Assess | снижает false-positive claims через состязательное опровержение | refuter rule-set + tournament trace model | PASS false-positive reduction experiment without MTTR regression |
| Live Runbook Compiler (LRC) | Assess | уменьшает runbook drift и ошибки устаревших процедур | runbook condition language + compiler prototype | PASS runbook mismatch reduction and operator acceptance |
| No-Regret Action Certificate (NRAC) | Assess | ограничивает риск действий перед execute | regret estimator + certificate format | PASS rollback/policy-violation reduction with bounded MTTR impact |
| Proof-carrying AI claims | Assess | снижает риск недоказуемых выводов | schema + verifier design | PASS e2e claims verifier + policy gate |
| Deterministic incident twin | Assess | воспроизводимость и time-travel диагностика | snapshot/replay model | PASS replay parity + operator UX validation |
| Causal scenario engine | Assess | безопасное what-if планирование действий | scenario DAG prototype | PASS action simulation accuracy budget |
| Policy simulation for actions | Trial | предотвращает risky execute | dry-run protocol + diff output | PASS stage33 e2e without side effects |
| GPU capability auto-profiling | Trial | предсказуемый spatial fallback | startup profile matrix | PASS weak-gpu budgets + fallback determinism |
| Contract fingerprint gates | Trial | раннее обнаружение drift | baseline fingerprint | PASS 30 days without false positives |
| AI-first without evidence | Hold | нарушает Evidence-first law | -- | -- |
| Big-bang delivery | Hold | повышает риск регрессий | -- | -- |
