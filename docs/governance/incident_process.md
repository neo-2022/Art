# Процесс Управления Инцидентами

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/governance/observability_gap_registry.md`
- `docs/governance/severity.md`

## Жизненный Цикл
1. обнаружение
2. triage
3. mitigation
4. resolution
5. postmortem
6. follow-up действия

## Роли
- `Incident Commander` — координирует ход инцидента
- `Communications` — отвечает за статусные коммуникации
- `Scribe` — фиксирует timeline, решения и evidence

## Правила Эскалации
- `observability_gap escalation` является обязательным контуром управления инцидентами.
- все `observability_gap.*` должны быть видимы в snapshot/stream
- для критичных контуров автоинциденты создаются по правилам registry
- если registry требует incident, обязательно должен быть `action_ref` на runbook

## Что Обязательно Фиксируется
- severity
- таймлайн
- evidence
- принятое решение
- follow-up actions
