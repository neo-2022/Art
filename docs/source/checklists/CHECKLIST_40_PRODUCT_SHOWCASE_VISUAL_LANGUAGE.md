# CHECKLIST 40 — Product Showcase + Visual Language
Файл: CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение visual language, brand/showcase layer, demo narrative
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Довести брендово-презентационный и demo-контур Art до состояния управляемого продукта без разрыва с боевым интерфейсом.

## Границы
- Включено: visual language canon, showcase spec, demo flow, motion rules, client-facing story.
- Исключено: маркетинговые материалы вне репозитория и вне source-of-truth контроля.

## Зависимости
- CHECKLIST 39 
- CHECKLIST 35 

## Шаги (строго линейно)
- [ ] 1. Сделать: оформить канон визуального языка Art как обязательный слой между operational UI и product showcase.
  - [ ] Проверка (pass/fail): visual language doc различает operational layer, atmospheric layer и showcase layer.
  - [ ] Артефакт результата: visual language doc diff.
- [ ] 2. Сделать: зафиксировать product showcase spec и клиентский walkthrough сценарий.
  - [ ] Проверка (pass/fail): showcase spec покрывает hero, system story, DNA explanation, evidence-first demo, fallback resilience, action safety.
  - [ ] Артефакт результата: showcase spec file.
- [ ] 3. Сделать: определить demo-safe motion/audio policy без конфликта с боевым UX и perf budget.
  - [ ] Проверка (pass/fail): rules содержат downgrade path и запрет ломать operational mode.
  - [ ] Артефакт результата: motion/audio policy diff.
- [ ] 4. Сделать: ввести customer-facing evidence narrative для показа реального прогресса.
  - [ ] Проверка (pass/fail): portal содержит связку delivery evidence -> release decisions -> project history -> showcase storyline.
  - [ ] Артефакт результата: portal diff + narrative artifact.
- [ ] 5. Сделать: зарегистрировать observability-gap для деградации showcase/demo режима.
  - [ ] Событие: `observability_gap.showcase_mode_degraded`.
  - [ ] evidence_min: `mode`, `degradation_reason`, `perf_profile`, `trace_id`, `build_id`.
  - [ ] action_ref: `docs/runbooks/showcase_mode_degraded.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/portal/ART_VISUAL_LANGUAGE.md
- [ ] docs/portal/PRODUCT_SHOWCASE_SPEC.md
- [ ] docs/portal/INDEX.md
- [ ] docs/portal/DELIVERY_EVIDENCE.md
- [ ] docs/runbooks/showcase_mode_degraded.md

## Тестирование
- [ ] unit: token/theme/motion policy schema checks.
- [ ] integration: showcase routes and asset references valid.
- [ ] e2e: walkthrough сценарий проходит без dead-end navigation.
- [ ] perf: showcase mode respects downgrade policy on weak-gpu profile.
- [ ] visual regression: key showcase surfaces stable.
- [ ] chaos: broken asset path switches to safe fallback presentation.

## CI gate
- [ ] `stage40-showcase-visual-gate`

## DoD
- [ ] Art имеет управляемый brand/showcase слой без конфликта с operational UI.
- [ ] Клиентская демонстрация опирается на реальные evidence и артефакты.
- [ ] observability-gap событие этапа 40 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_41 запрещён до полного закрытия CHECKLIST_40.
- Артефакты закрытия: showcase spec + walkthrough + perf logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
