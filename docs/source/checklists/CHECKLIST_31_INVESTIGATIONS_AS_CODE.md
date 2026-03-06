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
- [x] 1. Сделать: schema `investigation_doc_v1` (claims/decisions/actions/results/evidence_refs/audit_refs/proofs).
  - [x] Проверка (pass/fail): schema tests PASS.
  - [x] Артефакт результата: schema файл + test log.
- [x] 2. Сделать: parser/serializer c deterministic canonical output.
  - [x] Проверка (pass/fail): unit tests parser/serializer PASS.
  - [x] Артефакт результата: test output + fixtures.
- [x] 3. Сделать: fork/replay/compare операции.
  - [x] Проверка (pass/fail): integration tests fork/replay/compare PASS.
  - [x] Артефакт результата: integration log + replay fixtures.
- [x] 4. Сделать: compatibility policy и migration notes.
  - [x] Проверка (pass/fail): backward compatibility tests PASS.
  - [x] Артефакт результата: compatibility matrix документ.
- [x] 5. Сделать: observability-gap контроль replay/serialization сбоев.
  - [x] Событие: `observability_gap.investigation_replay_failed`.
  - [x] evidence_min: `doc_id`, `doc_version`, `step`, `error`, `trace_id`.
  - [x] action_ref: `docs/runbooks/investigation_replay_failed.md`.
  - [x] Проверка (pass/fail): запись есть в registry + runbook файл существует.
  - [x] Артефакт результата: registry diff + runbook.
- [x] 6. Сделать: внедрить экспериментальный LRC (Live Runbook Compiler) для InvestigationDoc runbook sections.
  - [x] Проверка (pass/fail): runbook компилируется в condition graph и в runtime помечает invalid шаги при нарушении evidence-предусловий.
  - [x] Артефакт результата: compiler test log + runbook mismatch report.
- [x] 7. Сделать: реализовать Investigation Library baseline UI contract без разрыва с L0/L1 слоями.
  - [x] Функции: `list/import/export/verify/replay` для InvestigationDoc.
  - [x] Ограничение: новые source-of-truth сущности не создаются, используется существующий InvestigationDoc контракт + local store metadata.
  - [x] Проверка (pass/fail): integration tests подтверждают стабильный цикл `import -> list -> verify -> replay`.
  - [x] Артефакт результата: investigation-library integration log.

## Документация (RU)
- [x] docs/source/investigations_as_code.md
- [x] docs/runbooks/investigation_replay_failed.md
- [x] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [x] Tier0 unit: parser/serializer.
- [x] Tier1 integration: fork/replay/compare.
- [x] Tier2 e2e: расследование от ingest до документа.
- [x] Tier2 e2e: LRC invalidation path + suggested evidence patch.
- [x] Tier2 e2e: Investigation Library (`import/export/verify/replay`) с сохранением lineage.
- [x] chaos: повреждённый document payload.
- [x] load: переносится в этап 34.
- [x] soak: переносится в этап 34.

## CI gate
- [x] `stage31-investigation-doc-tests`
- [x] `stage31-investigation-library-tests`

## DoD
- [x] InvestigationDoc сериализуется, версионируется и воспроизводится.
- [x] fork/replay/compare покрыты тестами.
- [x] Investigation Library baseline реализован и покрыт e2e/integration тестами.
- [x] observability-gap событие этапа 31 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_32 запрещён до полного закрытия CHECKLIST_31.
- Артефакты закрытия: tests + fixtures + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
