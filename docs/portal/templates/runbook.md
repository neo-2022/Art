# Runbook: <инцидент/алерт>

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/...`

## symptoms
- Какие сигналы/симптомы видит инженер или система.
- Что считается началом сценария.

## checks
1. Какие альтернативные причины надо исключить.
2. Какие evidence/поля/артефакты нужно проверить до remediation.
3. Какие зависимости и соседние слои могут быть источником дефекта.

## mitigations
1. Безопасные действия по локализации и устранению причины.
2. Запрещённые shortcut-действия, если они опасны.

## rollback
1. Как откатить последнее изменение, если remediation ухудшила состояние.
2. Что делать, если rollback неприменим.

## verification
1. Как доказать восстановление сервиса.
2. Как проверить, что regression не переехал в соседний слой.

## escalation
1. Когда поднимать SEV/инцидент.
2. Кому и с какими evidence эскалировать.

## evidence
- Какие логи/скрины/trace_id/audit_id/конфиги/version diffs обязательно сохранить.
- Что надо приложить до destructive действий.

## owner
- Кто основной исполнитель.
- Кто владелец компонента.

## degraded mode
- Какой degraded/read-only режим допустим.
- Условие выхода из degraded mode.
