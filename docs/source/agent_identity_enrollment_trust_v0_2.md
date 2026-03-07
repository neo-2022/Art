# Agent Identity Enrollment Trust v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/agent_deployment_transport_v0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md`
- `docs/source/checklists/CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Что это такое
Это предохранитель доверия к агентам и relay-пути.

Он отвечает на вопрос: откуда `Art` знает, что перед ним именно тот агент, за который он себя выдаёт, и что его путь доставки не подменён.

## Зачем он нужен
Без этого любой отправитель, умеющий говорить с `Core`, может выглядеть как доверенный источник.

Это опасно для:
- audit;
- incident truth;
- correlation между машинами;
- production deployment в разных сегментах и сетях.

## Что он обязан защищать
- identity самого агента;
- site/segment binding;
- enrollment path;
- relay trust chain;
- rotation/revocation;
- mismatch detection.

## Обязательный минимум
1. У агента есть идентичность, а не только URL и token.
2. У enrollment есть фиксированный bootstrap path.
3. У relay есть trust policy: trusted / partially trusted / untrusted.
4. При несовпадении identity, site, relay или scope агент не считается trusted.
5. Недоверенный агент не должен silently попадать в общий доверенный ingest.

## Что должен видеть оператор
- `agent_id`;
- `site_id`;
- `segment_id`;
- `relay_id`, если relay используется;
- trust status;
- время последнего успешного attestation/enrollment;
- active gaps по identity.

## Observability и реакция
Основной gap:
- `observability_gap.agent_identity_untrusted`

## Что считается зрелостью
`materialized`:
- trust path и revocation materialized в runtime;
- negative tests на mismatch есть;
- недоверенный агент не проходит в trusted path.

`planned`:
- документы и runbooks есть, но реальный enrollment/trust runtime ещё не завершён.

## Связанные runbooks
- `docs/runbooks/agent_identity_untrusted.md`
