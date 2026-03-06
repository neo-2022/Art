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
- [x] 2. Сделать: verify endpoint возвращает детерминированный статус и chain reason.
  - [x] Проверка (pass/fail): integration tests verify endpoint PASS.
  - [x] Артефакт результата: API test output.
- [x] 3. Сделать: UI verify flow отображает proof chain.
  - [x] Проверка (pass/fail): e2e verify tests PASS.
  - [x] Артефакт результата: e2e logs + screenshots.
- [x] 4. Сделать: attach proof refs в InvestigationDoc.
  - [x] Проверка (pass/fail): replay tests подтверждают наличие audit proof refs.
  - [x] Артефакт результата: replay fixture diff.
- [x] 5. Сделать: observability-gap контроль verify failures.
  - [x] Событие: `observability_gap.audit_merkle_verify_failed`.
  - [x] evidence_min: `audit_id`, `proof_hash`, `step`, `error`, `trace_id`.
  - [x] action_ref: `docs/runbooks/audit_merkle_verify_failed.md`.
  - [x] Проверка (pass/fail): registry запись + runbook файл.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 6. Сделать: зафиксировать безразрывную интеграцию Audit Verify в интерфейсную лестницу L1->L2.
  - [x] Требование: verify-действие доступно из `Incident Room`, `Investigation Library` и из контекстов `Flow Mode` для узлов с `audit_refs`.
  - [x] Требование: verify-статус (`verified|failed|unavailable`) отображается единообразно и локализуется (EN/RU).
  - [x] Проверка (pass/fail): e2e подтверждает стабильный маршрут `surface -> verify panel -> evidence lineage` без потери контекста.
  - [x] Артефакт результата: anti-breakage e2e report + screenshots.

## Документация (RU)
- [x] docs/source/audit_merkle_verify.md
- [x] docs/runbooks/audit_merkle_verify_failed.md

## Тестирование
- [x] Tier0 unit: hash/proof validation.
- [x] Tier1 integration: verify endpoint.
- [x] Tier2 e2e: UI verify flow.
- [x] Tier2 e2e: anti-breakage маршруты verify из `Incident Room`/`Investigation Library`/`Flow Mode`.
- [x] Tier2 i18n: verify labels/tooltips/errors присутствуют и консистентны для EN/RU.
- [x] chaos: tampered chain detection.
- [x] load: переносится в этап 34.
- [x] soak: переносится в этап 34.

## CI gate
- [x] `stage32-audit-merkle-tests`
- [x] `stage32-audit-ux-anti-breakage`

## DoD
- [x] Любое действие имеет проверяемый proof-chain.
- [x] verify endpoint/UI детерминированно объясняют причину fail.
- [x] verify UX встраивается в L1/L2 поверхности без интерфейсного разрыва и подтверждён anti-breakage e2e.
- [x] observability-gap событие этапа 32 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_33 запрещён до полного закрытия CHECKLIST_32.
- Артефакты закрытия: tests + screenshots + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
