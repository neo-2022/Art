# CHECKLIST 31 — Investigations-as-Code
Файл: CHECKLIST_31_INVESTIGATIONS_AS_CODE.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение InvestigationDoc schema, fork/replay/compare semantics
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Ввести обязательный артефакт расследования `InvestigationDoc` с versioning, fork/replay/compare и доказательной связностью.

## Границы
- Включено: schema документа, parser/serializer, replay интерфейсы, compatibility policy.
- Исключено: совместное редактирование в real-time.

## Зависимости
- CHECKLIST 29 (должен быть закрыт перед стартом CHECKLIST 31)
- CHECKLIST 30 (должен быть закрыт перед стартом CHECKLIST 31)

## Шаги (строго линейно)
- [ ] 1. Сделать: schema `investigation_doc_v1` (claims/decisions/actions/results/evidence_refs/audit_refs/proofs).
  - [ ] Проверка (pass/fail): schema tests PASS.
  - [ ] Артефакт результата: schema файл + test log.
- [ ] 2. Сделать: parser/serializer c deterministic canonical output.
  - [ ] Проверка (pass/fail): unit tests parser/serializer PASS.
  - [ ] Артефакт результата: test output + fixtures.
- [ ] 3. Сделать: fork/replay/compare операции.
  - [ ] Проверка (pass/fail): integration tests fork/replay/compare PASS.
  - [ ] Артефакт результата: integration log + replay fixtures.
- [ ] 4. Сделать: compatibility policy и migration notes.
  - [ ] Проверка (pass/fail): backward compatibility tests PASS.
  - [ ] Артефакт результата: compatibility matrix документ.
- [ ] 5. Сделать: observability-gap контроль replay/serialization сбоев.
  - [ ] Событие: `observability_gap.investigation_replay_failed`.
  - [ ] evidence_min: `doc_id`, `doc_version`, `step`, `error`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/investigation_replay_failed.md`.
  - [ ] Проверка (pass/fail): запись есть в registry + runbook файл существует.
  - [ ] Артефакт результата: registry diff + runbook.
- [ ] 6. Сделать: внедрить экспериментальный LRC (Live Runbook Compiler) для InvestigationDoc runbook sections.
  - [ ] Проверка (pass/fail): runbook компилируется в condition graph и в runtime помечает invalid шаги при нарушении evidence-предусловий.
  - [ ] Артефакт результата: compiler test log + runbook mismatch report.
- [ ] 7. Сделать: реализовать Investigation Library baseline UI contract без разрыва с L0/L1 слоями.
  - [ ] Функции: `list/import/export/verify/replay` для InvestigationDoc.
  - [ ] Ограничение: новые source-of-truth сущности не создаются, используется существующий InvestigationDoc контракт + local store metadata.
  - [ ] Проверка (pass/fail): integration tests подтверждают стабильный цикл `import -> list -> verify -> replay`.
  - [ ] Артефакт результата: investigation-library integration log.
 - [ ] 8. Сделать: зафиксировать human-agent collaboration path внутри InvestigationDoc.
   - [ ] Требование: документ различает `human-authored`, `agent-proposed`, `system-generated` sections/actions/decisions.
   - [ ] Требование: agent proposals сохраняют `approval_state` и ссылку на человеческое решение при approve/reject.
   - [ ] Проверка (pass/fail): export/import/replay сохраняет actor provenance без потери и без нормализации “в один тип автора”.
   - [ ] Артефакт результата: actor provenance replay log.
 - [ ] 9. Сделать: добавить bilingual replay/verify path для Investigation Library.
   - [ ] Требование: EN/RU labels для import/export/verify/replay/diff и состояний проверки консистентны.
   - [ ] Проверка (pass/fail): UI/e2e tests подтверждают parity EN/RU без потери навигации и без перепутанных статусов.
   - [ ] Артефакт результата: Investigation Library i18n parity log.

## Документация (RU)
- [ ] docs/source/investigations_as_code.md
- [ ] docs/runbooks/investigation_replay_failed.md
- [ ] docs/foundation/revolutionary_hypotheses.md
- [ ] docs/source/console_agent_interaction_model_v0_2.md

## Тестирование
- [ ] Tier0 unit: parser/serializer.
- [ ] Tier1 integration: fork/replay/compare.
- [ ] Tier2 e2e: расследование от ingest до документа.
- [ ] Tier2 e2e: LRC invalidation path + suggested evidence patch.
- [ ] Tier2 e2e: Investigation Library (`import/export/verify/replay`) с сохранением lineage.
- [ ] Tier2 e2e: actor provenance (`human|agent|system`) survives export/import/replay.
- [ ] Tier2 e2e: EN/RU parity for Investigation Library actions/states.
- [ ] chaos: повреждённый document payload.
- [ ] load: переносится в этап 34.
- [ ] soak: переносится в этап 34.

## CI gate
- [ ] `stage31-investigation-doc-tests`
- [ ] `stage31-investigation-library-tests`

## DoD
- [ ] InvestigationDoc сериализуется, версионируется и воспроизводится.
- [ ] fork/replay/compare покрыты тестами.
- [ ] Investigation Library baseline реализован и покрыт e2e/integration тестами.
- [ ] Human-agent collaboration path в InvestigationDoc формализован и воспроизводим.
- [ ] Билингвальный replay/verify/import/export контур подтверждён тестами.
- [ ] observability-gap событие этапа 31 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_32 запрещён до полного закрытия CHECKLIST_31.
- Артефакты закрытия: tests + fixtures + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
