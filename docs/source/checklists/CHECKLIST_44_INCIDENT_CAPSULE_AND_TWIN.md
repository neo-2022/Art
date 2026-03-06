# CHECKLIST 44 — Reproducible Incident Capsule + Deterministic Incident Twin
Файл: CHECKLIST_44_INCIDENT_CAPSULE_AND_TWIN.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение replay chain, capsule format, deterministic twin policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Сделать расследование и воспроизведение инцидентов переносимыми, проверяемыми и детерминированными.

Важно:
- replay discipline, versioned investigation artifacts и parity thinking должны появляться уже в 29, 31, 32, 34 и 37;
- stage44 завершает capsule/twin как самостоятельную production capability.

## Границы
- Включено: Reproducible Incident Capsule, Deterministic Incident Twin, replay parity.
- Исключено: ad-hoc dump without verify/replay semantics.

## Зависимости
- CHECKLIST 43 
- CHECKLIST 31 
- CHECKLIST 32 

## Шаги (строго линейно)
- [ ] 1. Сделать: определить и внедрить формат Reproducible Incident Capsule.
  - [ ] Проверка (pass/fail): capsule содержит snapshot, evidence refs, policy version, build metadata, audit proofs и проходит validation.
  - [ ] Артефакт результата: capsule schema + example artifact.
- [ ] 2. Сделать: внедрить Deterministic Incident Twin для replay and compare.
  - [ ] Проверка (pass/fail): twin replay на фиксированном corpus даёт deterministic parity result.
  - [ ] Артефакт результата: parity report + replay log.
- [ ] 3. Сделать: связать capsule/twin с Investigation Library и audit verify.
  - [ ] Проверка (pass/fail): investigation может экспортироваться в capsule, импортироваться обратно и верифицироваться.
  - [ ] Артефакт результата: import/export verify log.
- [ ] 4. Сделать: добавить diff/compare path между capsule versions и twin runs.
  - [ ] Проверка (pass/fail): differences between two incident capsules/twins explainable и machine-readable.
  - [ ] Артефакт результата: diff report artifact.
- [ ] 5. Сделать: зарегистрировать observability-gap для нарушения replay/capsule целостности.
  - [ ] Событие: `observability_gap.incident_capsule_integrity_failed`.
  - [ ] evidence_min: `capsule_id`, `twin_run_id`, `failure_mode`, `build_id`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/incident_capsule_integrity_failed.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/revolutionary_hypotheses.md
- [ ] docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md
- [ ] docs/runbooks/incident_capsule_integrity_failed.md

## Тестирование
- [ ] unit: capsule format validation.
- [ ] integration: export/import/verify path.
- [ ] e2e: deterministic twin replay on fixed corpus.
- [ ] regression: capsule survives schema evolution with version gates.
- [ ] soak: repeated replay parity.
- [ ] chaos: broken capsule/audit proof is rejected.

## CI gate
- [ ] `stage44-incident-capsule-twin-gate`

## DoD
- [ ] Incident capsule и deterministic twin стали реальным частью продукта, а не только концепцией.
- [ ] replay/compare path auditable и reproducible.
- [ ] observability-gap событие этапа 44 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_45 запрещён до полного закрытия CHECKLIST_44.
- Артефакты закрытия: capsule schema/artifacts + replay parity logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
