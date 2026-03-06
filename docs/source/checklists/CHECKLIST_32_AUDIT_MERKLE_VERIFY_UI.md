# CHECKLIST 32 — Audit + Merkle Verify UI
Файл: CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение hash chain, merkle proof format, verify UX
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Сделать audit криптографически проверяемым: attach proof, verify в UI, связка с InvestigationDoc.

## Границы
- Включено: audit proof pipeline, verify endpoint, UI verify projection.
- Исключено: внешние PKI/нотариальные сервисы.

## Зависимости
- CHECKLIST 15 (audit baseline)
- CHECKLIST 31 (Investigations-as-Code закрыт)

## Шаги (строго линейно)
- [x] 1. Сделать: attach merkle proof к audit entries.
  - [x] Проверка (pass/fail): proof consistency tests PASS.
  - [x] Артефакт результата: hash/proof test log.
- [ ] 2. Сделать: verify endpoint возвращает детерминированный статус и chain reason.
  - [ ] Проверка (pass/fail): integration tests verify endpoint PASS.
  - [ ] Артефакт результата: API test output.
- [ ] 3. Сделать: UI verify flow отображает proof chain.
  - [ ] Проверка (pass/fail): e2e verify tests PASS.
  - [ ] Артефакт результата: e2e logs + screenshots.
- [ ] 4. Сделать: attach proof refs в InvestigationDoc.
  - [ ] Проверка (pass/fail): replay tests подтверждают наличие audit proof refs.
  - [ ] Артефакт результата: replay fixture diff.
- [ ] 5. Сделать: observability-gap контроль verify failures.
  - [ ] Событие: `observability_gap.audit_merkle_verify_failed`.
  - [ ] evidence_min: `audit_id`, `proof_hash`, `step`, `error`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/audit_merkle_verify_failed.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 6. Сделать: зафиксировать безразрывную интеграцию Audit Verify в интерфейсную лестницу L1->L2.
  - [ ] Требование: verify-действие доступно из `Incident Room`, `Investigation Library` и из контекстов `Flow Mode` для узлов с `audit_refs`.
  - [ ] Требование: verify-статус (`verified|failed|unavailable`) отображается единообразно и локализуется (EN/RU).
  - [ ] Проверка (pass/fail): e2e подтверждает стабильный маршрут `surface -> verify panel -> evidence lineage` без потери контекста.
  - [ ] Артефакт результата: anti-breakage e2e report + screenshots.

## Документация (RU)
- [ ] docs/source/audit_merkle_verify.md
- [ ] docs/runbooks/audit_merkle_verify_failed.md

## Тестирование
- [ ] Tier0 unit: hash/proof validation.
- [ ] Tier1 integration: verify endpoint.
- [ ] Tier2 e2e: UI verify flow.
- [ ] Tier2 e2e: anti-breakage маршруты verify из `Incident Room`/`Investigation Library`/`Flow Mode`.
- [ ] Tier2 i18n: verify labels/tooltips/errors присутствуют и консистентны для EN/RU.
- [ ] chaos: tampered chain detection.
- [ ] load: переносится в этап 34.
- [ ] soak: переносится в этап 34.

## CI gate
- [ ] `stage32-audit-merkle-tests`
- [ ] `stage32-audit-ux-anti-breakage`

## DoD
- [ ] Любое действие имеет проверяемый proof-chain.
- [ ] verify endpoint/UI детерминированно объясняют причину fail.
- [ ] verify UX встраивается в L1/L2 поверхности без интерфейсного разрыва и подтверждён anti-breakage e2e.
- [ ] observability-gap событие этапа 32 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_33 запрещён до полного закрытия CHECKLIST_32.
- Артефакты закрытия: tests + screenshots + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
