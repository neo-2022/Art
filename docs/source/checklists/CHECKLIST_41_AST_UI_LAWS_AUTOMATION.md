# CHECKLIST 41 — AST UI Laws + Self-Healing Docs/Tests Automation
Файл: CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение UI law model, contracts diff pipeline, docs automation policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Перевести продвинутую автоматизацию UI-laws и contract-driven maintenance в обязательный механизм качества.

## Границы
- Включено: AST/type-level UI law checks, self-healing test impact map, docs-from-code/tests pipeline.
- Исключено: автоматическое изменение кода без review и evidence.

## Зависимости
- CHECKLIST 40 
- CHECKLIST 30 

## Шаги (строго линейно)
- [ ] 1. Сделать: внедрить AST/type-level enforcement для `tooltip everywhere`, `one-click-to-evidence`, `observed -> evidence_refs`.
  - [ ] Проверка (pass/fail): static law checker FAIL на контролируемых нарушениях.
  - [ ] Артефакт результата: checker code + negative test log.
- [ ] 2. Сделать: внедрить contract diff impact map для автодетекции затронутых тестов.
  - [ ] Проверка (pass/fail): изменение schema/OpenAPI порождает deterministic impact report для тестов.
  - [ ] Артефакт результата: impact report example + CI log.
- [ ] 3. Сделать: внедрить docs-from-code/tests pipeline для живых примеров и инвариантов.
  - [ ] Проверка (pass/fail): целевые reference docs получают сгенерированные примеры из тестов без ручного копирования.
  - [ ] Артефакт результата: generated docs artifact.
- [ ] 4. Сделать: ввести review gate против auto-fix без human/owner acknowledgement.
  - [ ] Проверка (pass/fail): pipeline не может silently rewrite contract/docs/test without explicit recorded approval.
  - [ ] Артефакт результата: gate log + policy diff.
- [ ] 5. Сделать: зарегистрировать observability-gap для automation drift.
  - [ ] Событие: `observability_gap.automation_drift_detected`.
  - [ ] evidence_min: `automation_area`, `contract_ref`, `expected_output`, `actual_output`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/automation_drift_detected.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md
- [ ] docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
- [ ] docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md
- [ ] docs/runbooks/automation_drift_detected.md

## Тестирование
- [ ] unit: AST rules parser/checker.
- [ ] integration: contract diff impact report.
- [ ] e2e: intentionally broken component is blocked before runtime.
- [ ] regression: docs examples stay synced with tests.
- [ ] chaos: malformed schema diff does not produce silent pass.
- [ ] soak: repeated regeneration does not cause nondeterministic output.

## CI gate
- [ ] `stage41-ast-ui-laws-automation-gate`

## DoD
- [ ] UI-laws enforce не только runtime/tests, но и static/AST path.
- [ ] contract evolution получает deterministic test/doc impact mapping.
- [ ] observability-gap событие этапа 41 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_42 запрещён до полного закрытия CHECKLIST_41.
- Артефакты закрытия: checker logs + impact reports + generated-doc evidence + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
