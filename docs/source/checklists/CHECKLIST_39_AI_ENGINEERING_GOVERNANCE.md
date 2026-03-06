# CHECKLIST 39 — AI Engineering Governance
Файл: CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение operating model AI-команды, stage-ladder policy, review duty matrix
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Превратить AI Engineering Operating Model из описательного документа в обязательный управляемый контур исполнения проекта.

## Границы
- Включено: role map, review-duty matrix, lessons learned ledger, knowledge contour discipline, truthfulness gate.
- Исключено: замена человеческого владельца проекта автоматическими решениями.

## Зависимости
- CHECKLIST 38 

## Шаги (строго линейно)
- [ ] 1. Сделать: зафиксировать machine-readable role/task mapping для критичных контуров `core/api/ui/test/docs/release`.
  - [ ] Проверка (pass/fail): role map существует в репозитории и покрывает все критичные контуры без пустых owner-полей.
  - [ ] Артефакт результата: role map file + validation log.
- [ ] 2. Сделать: ввести review-duty matrix для критичных изменений.
  - [ ] Проверка (pass/fail): matrix различает implementer/reviewer для DNA, security, release, actions, checklist truthfulness.
  - [ ] Артефакт результата: governance diff + matrix artifact.
- [ ] 3. Сделать: ввести lessons learned ledger и обязательную post-stage retro запись.
  - [ ] Проверка (pass/fail): ledger содержит формат записи, owner, дату, corrective action и ссылку на evidence.
  - [ ] Артефакт результата: ledger file + example record.
- [ ] 4. Сделать: ввести truthfulness gate для foundation/checklists/docs изменений.
  - [ ] Проверка (pass/fail): CI FAIL, если изменены foundation/checklists без traceability update и without evidence-aware status sync.
  - [ ] Артефакт результата: CI script + negative log.
- [ ] 5. Сделать: зарегистрировать observability-gap для нарушений AI engineering governance.
  - [ ] Событие: `observability_gap.ai_governance_violation`.
  - [ ] evidence_min: `change_scope`, `missing_artifact`, `missing_reviewer`, `trace_id`, `check_name`.
  - [ ] action_ref: `docs/runbooks/ai_governance_violation.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md
- [ ] docs/governance/ai_role_task_matrix.yaml
- [ ] docs/governance/review_duty_matrix.md
- [ ] docs/governance/lessons_learned_ledger.md
- [ ] docs/runbooks/ai_governance_violation.md

## Тестирование
- [ ] unit: validation role map schema.
- [ ] integration: truthfulness gate negative scenario.
- [ ] e2e: critical change requires reviewer split.
- [ ] soak: repeated stage close/update cycle keeps ledger consistency.
- [ ] load: не применяется на этапе 39.
- [ ] chaos: manual metadata drift attempt is blocked.

## CI gate
- [ ] `stage39-ai-governance-gate`

## DoD
- [ ] AI operating model перестал быть только описанием и enforce в CI.
- [ ] Для критичных контуров существует review split.
- [ ] Lessons learned контур обязателен и traceable.
- [ ] observability-gap событие этапа 39 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_40 запрещён до полного закрытия CHECKLIST_39.
- Артефакты закрытия: role map + duty matrix + ledger + CI logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
