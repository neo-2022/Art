# Secure Actions Protocol v2

Последняя актуализация: 2026-03-06

## Цель
Исключить silent actions и обеспечить policy-driven исполнение действий.

## Обязательный pipeline
1. preflight
2. policy check
3. execute
4. action result
5. audit record
6. merkle proof attach

## Инварианты
- Action без preflight запрещён.
- Policy denial не скрывается.
- Результат действия всегда имеет audit link.
- Action Studio работает по policy-as-ui: доступные action/target/params динамически ограничены активной ролью и policy id.
- Simulation mode (`/api/v1/actions/simulate`) всегда возвращает policy verdict + preflight diff и не создаёт side effects.
- Для критичных actions (`service.rollback`, `service.terminate`) действует экспериментальный NRAC-gate: execute запрещён без `x-action-nrac-regret` или при regret выше policy threshold.

## Проверка
- unit policy validators
- integration action chain
- e2e Action Studio
