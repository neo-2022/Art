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
- [x] 1. Сделать: endpoint `/api/v2/evidence/{evidence_id}` + access scope enforcement.
  - [x] Проверка (pass/fail): `cargo test -p art-core v2_evidence_access_scope_enforcement_tests` PASS.
  - [x] Артефакт результата: лог теста (200/403/404 ветки).
- [x] 2. Сделать: schema `claim_v2.json` с запретом claim без `proof_set`.
  - [x] Проверка (pass/fail): contract validation tests PASS.
  - [x] Артефакт результата: schema diff + test log.
- [x] 3. Сделать: schema `dialog_message_v2.json` с фиксированными `type`.
  - [x] Проверка (pass/fail): protocol schema tests PASS.
  - [x] Артефакт результата: schema test log.
- [x] 4. Сделать: runtime UI-law “claim without evidence_refs forbidden”.
  - [x] Проверка (pass/fail): `corepack pnpm --filter @art/ui-laws run test` PASS.
  - [x] Артефакт результата: unit test output.
- [x] 5. Сделать: добавить static UI-law lint checks для tooltip/evidence-link инвариантов.
  - [x] Проверка (pass/fail): `corepack pnpm run console:lint` выявляет нарушения UI-law как FAIL.
  - [x] Артефакт результата: lint output с проверкой законов.
- [x] 6. Сделать: policy для redaction/access_scope в local stores/index.
  - [x] Проверка (pass/fail): тесты показывают, что секреты не попадают в индекс.
  - [x] Артефакт результата: privacy test log.
- [x] 7. Сделать: зафиксировать semver-политику UI-laws и обратную совместимость law_version.
  - [x] Проверка (pass/fail): пакет `packages/ui-laws` содержит `law_version` и changelog migration rules.
  - [x] Артефакт результата: package diff + changelog.
- [x] 8. Сделать: внедрить observability-gap контроль нарушений evidence/claim/UI-law/privacy contracts.
  - [x] События: `observability_gap.evidence_scope_violation`, `observability_gap.claim_without_evidence`, `observability_gap.ui_law_violation`, `observability_gap.evidence_privacy_violation`.
  - [x] evidence_min:
    - `evidence_scope_violation`: `evidence_id`, `required_scope`, `actor_role`, `trace_id`.
    - `claim_without_evidence`: `claim_id`, `component`, `rule`, `trace_id`.
    - `ui_law_violation`: `component`, `rule_id`, `law_version`, `trace_id`, `severity`.
    - `evidence_privacy_violation`: `evidence_id`, `actor_role`, `required_scope`, `redaction_policy_id`, `trace_id`.
  - [x] action_ref: `docs/runbooks/evidence_scope_violation.md`, `docs/runbooks/claim_without_evidence.md`, `docs/runbooks/ui_law_violation.md`, `docs/runbooks/evidence_privacy_violation.md`.
  - [x] Проверка (pass/fail): registry содержит все записи и runbook файлы существуют.
  - [x] Артефакт результата: registry diff + runbooks.
- [x] 9. Сделать: добавить обязательный `evidence_lineage_id` для трассировки event -> evidence -> claim -> investigation.
  - [x] Проверка (pass/fail): schema/tests подтверждают наличие `evidence_lineage_id` в critical paths.
  - [x] Артефакт результата: schema diff + integration test log.
- [x] 10. Сделать: внедрить экспериментальный каркас RTP (Refutation Tournament Protocol) для ClaimV2.
  - [x] Проверка (pass/fail): для каждого claim формируется tournament verdict (`passed`/`contested`) с trace refuter-результатов.
  - [x] Артефакт результата: RTP experiment report + sample tournament traces.
- [x] 11. Сделать: внедрить Truth Modes contract (`observed|derived|predicted`) и обязательный `meta`-контур в stage30 UI/contracts.
  - [x] Проверка (pass/fail): schemas `claim_v2`, `dialog_message_v2`, `snapshot_v2` содержат `meta.truth_mode` и соответствующие mandatory поля.
  - [x] Проверка (pass/fail): observed payload без `meta.evidence_refs` детерминированно отклоняется UI-law тестом.
  - [x] Артефакт результата: schema diff + stage30 truth-modes test log.

## Документация (RU)
- [x] docs/contracts/v2/schemas/evidence_block.json
- [x] docs/contracts/v2/schemas/claim_v2.json
- [x] docs/contracts/v2/schemas/dialog_message_v2.json
- [x] docs/contracts/v2/schemas/evidence_lineage_v2.json
- [x] docs/contracts/v2/schemas/evidence_item.json
- [x] docs/contracts/v2/schemas/gap_event.json
- [x] docs/contracts/v2/schemas/slo_violation.json
- [x] docs/contracts/v2/schemas/dna_cluster.json
- [x] docs/runbooks/evidence_scope_violation.md
- [x] docs/runbooks/claim_without_evidence.md
- [x] docs/runbooks/ui_law_violation.md
- [x] docs/runbooks/evidence_privacy_violation.md
- [x] docs/source/risk_register_v0_2.md
- [x] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [x] Tier0: schema validation.
- [x] Tier1: evidence scope runtime enforcement.
- [x] Tier2: ui-laws runtime checks.
- [x] Tier2: ui-laws static lint checks.
- [x] e2e: one-click-to-evidence path from foundation UI.
- [x] e2e: lineage trace path event -> evidence -> claim -> investigation.
- [x] e2e: RTP verdict отображается и не позволяет silently повысить contested claim до valid.
- [x] regression: L0 shell invariants не ломаются после внедрения Truth Modes.
- [x] chaos: scope downgrade scenario.
- [x] load: переносится в этап 34.
- [x] soak: переносится в этап 34.

## CI gate
- [x] `stage30-evidence-claims-tests`
- [x] `stage30-truth-modes-tests`
- [x] `console-test`

## DoD
- [x] Evidence endpoint работает с корректным scope enforcement.
- [x] Claims/Dialogic contracts валидируются автоматически.
- [x] UI-law “no claim without evidence_refs” enforced.
- [x] Truth Modes contract реализован и проверяется для observed/derived/predicted.
- [x] observability-gap события этапа 30 зарегистрированы и имеют runbook.
- [x] Риски R3 и R9 из risk register закрыты тестами и runbook-процедурами.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_31 запрещён до полного закрытия CHECKLIST_30.
- Артефакты закрытия: API/test logs + registry/runbook diffs.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
