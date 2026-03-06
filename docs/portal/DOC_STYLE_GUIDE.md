# Стиль Документации (Diataxis)

## Source of truth (обязательно)
- `docs/README.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Классы документов
- `Tutorial`: обучение шаг за шагом.
- `How-to`: задача или операция.
- `Reference`: спецификация и контракт.
- `Explanation`: объяснение причин и trade-offs.

## Нормативность
- MUST/SHOULD/MAY используются явно.
- Нельзя менять нормативные правила в tutorial/how-to.
- Любое смысловое изменение контрактов идет через `docs/source/*` и checklist update.

## Формат
- Короткие секции, явные предпосылки, верификация, rollback.
- Примеры запросов/ответов в fenced code blocks.
- Для runbook обязательны: Symptoms, Diagnosis, Resolution, Evidence.
