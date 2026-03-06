# CHECKLIST 42 — Evidence Intelligence + Drift Detection
Файл: CHECKLIST_42_EVIDENCE_INTELLIGENCE_AND_DRIFT.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение claim quality model, DNA drift policy, AI proof requirements
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Реализовать интеллектуальные доказательные механизмы, которые были утверждены как differentiators Art, но ещё не доведены до продукта.

Важно:
- claim quality, drift-awareness и proof-carrying AI должны закладываться уже при прохождении 29, 30, 31, 34 и 37;
- stage42 завершает отдельные алгоритмы, gate’ы и UX-hardening этих возможностей.

## Границы
- Включено: Proof Completeness Score, DNA Drift Radar, Proof-Carrying AI Claims.
- Исключено: недоказуемые AI-выводы и скрытая эвристика без explanation path.

## Зависимости
- CHECKLIST 41 
- CHECKLIST 29 
- CHECKLIST 30 

## Шаги (строго линейно)
- [ ] 1. Сделать: внедрить Proof Completeness Score для claim quality.
  - [ ] Проверка (pass/fail): score model документирована, вычисляется детерминированно и отображается в UI без смешения со статусом claim validity.
  - [ ] Артефакт результата: score spec + test log + UI artifact.
- [ ] 2. Сделать: внедрить DNA Drift Radar для раннего выявления новых problem classes.
  - [ ] Проверка (pass/fail): drift detector выдаёт reproducible signal на controlled corpus и имеет bounded false-positive policy.
  - [ ] Артефакт результата: drift report + corpus test log.
- [ ] 3. Сделать: внедрить Proof-Carrying AI Claims как обязательный AI law.
  - [ ] Проверка (pass/fail): AI/generated claim without `evidence_refs` блокируется и маркируется как invalid output.
  - [ ] Артефакт результата: gate log + negative AI claim artifact.
- [ ] 4. Сделать: привязать новые механизмы к lineage/explanation path и anti-overload UX policy.
  - [ ] Проверка (pass/fail): UI раскрывает “из чего получен score/drift/proof status”, не перегружая основную поверхность.
  - [ ] Артефакт результата: UX spec diff + integration log.
- [ ] 5. Сделать: зарегистрировать observability-gap для деградации evidence-intelligence контура.
  - [ ] Событие: `observability_gap.evidence_intelligence_degraded`.
  - [ ] evidence_min: `subsystem`, `model_version`, `dataset_ref`, `failure_mode`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/evidence_intelligence_degraded.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/revolutionary_hypotheses.md
- [ ] docs/foundation/frontier_tech_radar.md
- [ ] docs/source/FOUNDATION_CONSTITUTION_V0_2.md
- [ ] docs/runbooks/evidence_intelligence_degraded.md

## Тестирование
- [ ] unit: score/drift algorithms.
- [ ] integration: claims/UI lineage binding.
- [ ] e2e: AI claim without evidence is blocked.
- [ ] perf: score/drift path respects budget.
- [ ] soak: drift signal remains stable on replay corpus.
- [ ] regression: proof-carrying AI laws survive schema evolution.

## CI gate
- [ ] `stage42-evidence-intelligence-gate`

## DoD
- [ ] Approved differentiators `Proof Completeness Score`, `DNA Drift Radar`, `Proof-Carrying AI Claims` стали частью продукта.
- [ ] Ни один AI claim не проходит без доказательной базы.
- [ ] observability-gap событие этапа 42 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_43 запрещён до полного закрытия CHECKLIST_42.
- Артефакты закрытия: score spec/tests + drift corpus/tests + AI law gate logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
