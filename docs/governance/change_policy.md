# Политика Изменений

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `docs/governance/repo_protection_evidence.md`

## Базовые Правила
- прямые коммиты в `main` запрещены
- изменения проходят только через PR
- PR должен ссылаться на релевантный чек-лист и evidence
- review обязателен

## Требования К Изменению
- изменение должно быть трассируемо к source-of-truth
- если меняется контракт или правило, это должно быть отражено в каноне
- если меняется checklist item, должно быть понятно, какой артефакт подтверждает закрытие

## Запрещено
- формальное закрытие без выполнения
- обход branch protection
- документировать одно, а внедрять другое
