# Политика Evidence

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/governance/evidence/README.md`
- `docs/governance/evidence/evidence_ledger.yaml`

## Назначение

Evidence — это обязательное подтверждение того, что работа реально выполнена, а не только описана.

## Для Чек-Листа Обязательны
- команды
- логи
- скриншоты или UI-артефакты, если применимо
- ссылки на PR, commit или CI run

## Для Инцидента Обязательны
- evidence snapshot
- таймлайн
- ссылки на артефакты и runbooks

## Хранение
- основной каталог: `docs/governance/evidence/`
- индексируемый реестр: `docs/governance/evidence/evidence_ledger.yaml`

## Блокирующее Правило

Этап, изменение или release без соответствующего evidence не считается подтверждённым.
