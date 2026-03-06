# Radar Перспективных Технологий (Art / Console)

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/foundation/revolutionary_hypotheses.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/source/risk_register_v0_2.md`

Последняя актуализация: 2026-03-06
Статус: ACTIVE

## Назначение
Фиксировать перспективные технологии и исследовательские направления без нарушения Primary-инвариантов проекта.

## Правила радара
- `Adopt` — можно применять в production-контуре.
- `Trial` — можно запускать контролируемые эксперименты.
- `Assess` — требуется исследование и прототип.
- `Hold` — использовать запрещено в текущем контуре.
- Перевод темы между кольцами требует checklist mapping, evidence и risk review.

## Radar
| Topic | Ring | Why | Entry Criteria | Exit Criteria | Checklist mapping |
|---|---|---|---|---|---|
| Refutation Tournament Protocol (RTP) | Trial | снижает false-positive claims через состязательное опровержение | refuter rule-set + tournament trace model | PASS false-positive reduction experiment without MTTR regression | 30, 34 |
| Live Runbook Compiler (LRC) | Trial | уменьшает runbook drift и ошибки устаревших процедур | runbook condition language + compiler prototype | PASS runbook mismatch reduction and operator acceptance | 31, 34 |
| No-Regret Action Certificate (NRAC) | Trial | ограничивает риск действий перед execute | regret estimator + certificate format | PASS rollback/policy-violation reduction with bounded MTTR impact | 33, 34 |
| Proof-carrying AI claims | Assess | снижает риск недоказуемых выводов | schema + verifier design | PASS e2e claims verifier + policy gate | 30, 33 |
| Deterministic incident twin | Assess | воспроизводимость и time-travel диагностика | snapshot/replay model | PASS replay parity + operator UX validation | 31, 34 |
| Proof Completeness Score | Assess | помогает измерять силу доказательной базы claim | score formula + UI cue + validation corpus | PASS quality uplift without cognitive overload | 30, 34 |
| DNA Drift Radar | Assess | раннее обнаружение новых классов проблем | drift metric + corpus + alert policy | PASS lead-time advantage with bounded false positives | 29, 34 |
| Counterfactual Action Simulator | Assess | безопасное what-if планирование действий | scenario/replay model + no-side-effect dry-run | PASS forecast usefulness and bounded regret | 33, 34 |
| Reproducible Incident Capsule | Assess | переносимый и проверяемый слепок инцидента | capsule format + verify/replay chain | PASS capsule replay parity and audit validation | 31, 32 |
| Autonomic UX Governor | Assess | удерживает UX в пределах perf budget | telemetry loop + downgrade ladder | PASS weak-gpu/operator acceptance budgets | 34, 35 |
| Policy simulation for actions | Trial | предотвращает risky execute | dry-run protocol + diff output | PASS stage33 e2e without side effects | 33 |
| GPU capability auto-profiling | Trial | предсказуемый spatial fallback | startup profile matrix | PASS weak-gpu budgets + fallback determinism | 35 |
| Contract fingerprint gates | Trial | раннее обнаружение drift | baseline fingerprint | PASS 30 days without false positives | 29, 38 |
| AI-first without evidence | Hold | нарушает Evidence-first law | -- | -- | 30 |
| Big-bang delivery | Hold | повышает риск регрессий | -- | -- | 38 |

## Правило принятия в продукт
Тема из колец `Assess` и `Trial` может стать production-механикой только если:
- существует checklist mapping;
- определён наблюдаемый KPI или quality metric;
- есть gate или evidence, подтверждающие полезность;
- риск-register не содержит незакрытого release-blocker по этой теме.
