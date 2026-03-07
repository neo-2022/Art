# Release Truth Enforcement v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/release/release_process.md`
- `RELEASE_CHECKLIST.md`
- `docs/governance/release_decisions/latest_go_no_go.md`

## Что это такое
Это предохранитель, который не даёт релизному контуру заявлять больше, чем реально подтверждено кодом, CI, evidence и runtime.

## Зачем он нужен
Иначе появляются самые опасные ложные состояния:
- release docs говорят `готово`, а runtime не готов;
- `GO/NO-GO` устарел;
- `README`, `CHANGELOG`, `RELEASE_CHECKLIST` и evidence живут отдельно друг от друга.

## Основной закон
Релиз считается правдивым только если:
- release metadata актуальна относительно текущего `HEAD`;
- evidence относится к той же ревизии;
- нет stale claims;
- release blockers действительно пройдены.

## Что обязан проверять этот guard
- согласованность `RELEASE_CHECKLIST`, `CHANGELOG`, `GO/NO-GO`, `DELIVERY_EVIDENCE`;
- отсутствие overclaim по readiness, certified, support, rollout status;
- отсутствие stale ссылки на старый CI или старый evidence run.

## Observability и реакция
Gap:
- `observability_gap.release_truth_mismatch`

## Что должен видеть оператор
- какая именно часть релиза устарела или врёт;
- какой документ или evidence рассинхронизирован;
- какой rollout нужно остановить.

## Связанные runbooks
- `docs/runbooks/release_truth_mismatch.md`
