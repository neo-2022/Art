# Индекс схем v2

## Source of truth
- [../openapi.yaml](../openapi.yaml)
- [../../../source/FOUNDATION_CONSTITUTION_V0_2.md](../../../source/FOUNDATION_CONSTITUTION_V0_2.md)
- [../../../source/Art_v1_spec_final.md](../../../source/Art_v1_spec_final.md)
- [../../../source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md](../../../source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md)
- [../../../source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md](../../../source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md)
- [../../../source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md](../../../source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md)

## Назначение
Этот каталог содержит машинно-читабельные JSON Schema для контрактов v2.

Он нужен для того, чтобы:
- API, UI и тесты работали по одному формальному описанию;
- drift между документацией и реализацией выявлялся автоматически;
- каталог схем был не «безымянной папкой», а полноценным индексируемым узлом документационного дерева.

## Что здесь лежит
- события и снимки состояния;
- DNA и evidence-сущности;
- claim/dialog/investigation контракты;
- tenancy, quota и смежные v2-схемы.

## Правило синхронизации
Любое изменение схем в этом каталоге должно сопровождаться:
- обновлением fingerprint/traceability, если это требуется;
- проверкой stage-gates, завязанных на v2 contracts;
- пересчётом документационного дерева.
