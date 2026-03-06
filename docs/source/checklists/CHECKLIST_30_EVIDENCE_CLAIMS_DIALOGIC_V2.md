# CHECKLIST 30 — Evidence / Claims / Dialogic v2
Файл: CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение EvidenceBlock/ClaimV2/DialogMessageV2 и access scope model
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Реализовать proof-carrying объекты v2: EvidenceBlock, ClaimV2, DialogMessageV2 и enforce их runtime-валидации в Core и Console foundation.

## Границы
- Включено: endpoint evidence, scope enforcement, claim/dialog schemas, ui-laws.
- Исключено: полнофункциональный Incident Room UI (этап 31+).

## Зависимости
- CHECKLIST 29 (должен быть закрыт перед стартом CHECKLIST 30)
- CHECKLIST 15 (audit/rbac baseline)
- CHECKLIST 02 (privacy baseline)

## Шаги (строго линейно)
- [ ] 1. Сделать: endpoint `/api/v2/evidence/{evidence_id}` + access scope enforcement.
  - [ ] Проверка (pass/fail): `cargo test -p art-core v2_evidence_access_scope_enforcement_tests` PASS.
  - [ ] Артефакт результата: лог теста (200/403/404 ветки).
- [ ] 2. Сделать: schema `claim_v2.json` с запретом claim без `proof_set`.
  - [ ] Проверка (pass/fail): contract validation tests PASS.
  - [ ] Артефакт результата: schema diff + test log.
- [ ] 3. Сделать: schema `dialog_message_v2.json` с фиксированными `type`.
  - [ ] Проверка (pass/fail): protocol schema tests PASS.
  - [ ] Артефакт результата: schema test log.
- [ ] 4. Сделать: runtime UI-law “claim without evidence_refs forbidden”.
  - [ ] Проверка (pass/fail): `corepack pnpm --filter @art/ui-laws run test` PASS.
  - [ ] Артефакт результата: unit test output.
- [ ] 5. Сделать: добавить static UI-law lint checks для tooltip/evidence-link инвариантов.
  - [ ] Проверка (pass/fail): `corepack pnpm run console:lint` выявляет нарушения UI-law как FAIL.
  - [ ] Артефакт результата: lint output с проверкой законов.
- [ ] 6. Сделать: policy для redaction/access_scope в local stores/index.
  - [ ] Проверка (pass/fail): тесты показывают, что секреты не попадают в индекс.
  - [ ] Артефакт результата: privacy test log.
- [ ] 7. Сделать: зафиксировать semver-политику UI-laws и обратную совместимость law_version.
  - [ ] Проверка (pass/fail): пакет `packages/ui-laws` содержит `law_version` и changelog migration rules.
  - [ ] Артефакт результата: package diff + changelog.
- [ ] 8. Сделать: внедрить observability-gap контроль нарушений evidence/claim/UI-law/privacy contracts.
  - [ ] События: `observability_gap.evidence_scope_violation`, `observability_gap.claim_without_evidence`, `observability_gap.ui_law_violation`, `observability_gap.evidence_privacy_violation`.
  - [ ] evidence_min:
    - `evidence_scope_violation`: `evidence_id`, `required_scope`, `actor_role`, `trace_id`.
    - `claim_without_evidence`: `claim_id`, `component`, `rule`, `trace_id`.
    - `ui_law_violation`: `component`, `rule_id`, `law_version`, `trace_id`, `severity`.
    - `evidence_privacy_violation`: `evidence_id`, `actor_role`, `required_scope`, `redaction_policy_id`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/evidence_scope_violation.md`, `docs/runbooks/claim_without_evidence.md`, `docs/runbooks/ui_law_violation.md`, `docs/runbooks/evidence_privacy_violation.md`.
  - [ ] Проверка (pass/fail): registry содержит все записи и runbook файлы существуют.
  - [ ] Артефакт результата: registry diff + runbooks.
- [ ] 9. Сделать: добавить обязательный `evidence_lineage_id` для трассировки event -> evidence -> claim -> investigation.
  - [ ] Проверка (pass/fail): schema/tests подтверждают наличие `evidence_lineage_id` в critical paths.
  - [ ] Артефакт результата: schema diff + integration test log.
- [ ] 10. Сделать: внедрить экспериментальный каркас RTP (Refutation Tournament Protocol) для ClaimV2.
  - [ ] Проверка (pass/fail): для каждого claim формируется tournament verdict (`passed`/`contested`) с trace refuter-результатов.
  - [ ] Артефакт результата: RTP experiment report + sample tournament traces.
- [ ] 11. Сделать: внедрить Truth Modes contract (`observed|derived|predicted`) и обязательный `meta`-контур в stage30 UI/contracts.
  - [ ] Проверка (pass/fail): schemas `claim_v2`, `dialog_message_v2`, `snapshot_v2` содержат `meta.truth_mode` и соответствующие mandatory поля.
  - [ ] Проверка (pass/fail): observed payload без `meta.evidence_refs` детерминированно отклоняется UI-law тестом.
  - [ ] Артефакт результата: schema diff + stage30 truth-modes test log.

## Документация (RU)
- [ ] docs/contracts/v2/schemas/evidence_block.json
- [ ] docs/contracts/v2/schemas/claim_v2.json
- [ ] docs/contracts/v2/schemas/dialog_message_v2.json
- [ ] docs/contracts/v2/schemas/evidence_lineage_v2.json
- [ ] docs/contracts/v2/schemas/evidence_item.json
- [ ] docs/contracts/v2/schemas/gap_event.json
- [ ] docs/contracts/v2/schemas/slo_violation.json
- [ ] docs/contracts/v2/schemas/dna_cluster.json
- [ ] docs/runbooks/evidence_scope_violation.md
- [ ] docs/runbooks/claim_without_evidence.md
- [ ] docs/runbooks/ui_law_violation.md
- [ ] docs/runbooks/evidence_privacy_violation.md
- [ ] docs/source/risk_register_v0_2.md
- [ ] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [ ] Tier0: schema validation.
- [ ] Tier1: evidence scope runtime enforcement.
- [ ] Tier2: ui-laws runtime checks.
- [ ] Tier2: ui-laws static lint checks.
- [ ] e2e: one-click-to-evidence path from foundation UI.
- [ ] e2e: lineage trace path event -> evidence -> claim -> investigation.
- [ ] e2e: RTP verdict отображается и не позволяет silently повысить contested claim до valid.
- [ ] regression: L0 shell invariants не ломаются после внедрения Truth Modes.
- [ ] chaos: scope downgrade scenario.
- [ ] load: переносится в этап 34.
- [ ] soak: переносится в этап 34.

## CI gate
- [ ] `stage30-evidence-claims-tests`
- [ ] `stage30-truth-modes-tests`
- [ ] `console-test`

## DoD
- [ ] Evidence endpoint работает с корректным scope enforcement.
- [ ] Claims/Dialogic contracts валидируются автоматически.
- [ ] UI-law “no claim without evidence_refs” enforced.
- [ ] Truth Modes contract реализован и проверяется для observed/derived/predicted.
- [ ] observability-gap события этапа 30 зарегистрированы и имеют runbook.
- [ ] Риски R3 и R9 из risk register закрыты тестами и runbook-процедурами.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_31 запрещён до полного закрытия CHECKLIST_30.
- Артефакты закрытия: API/test logs + registry/runbook diffs.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
