# Runbook: Ingress Shield Degraded

## Сигналы
- `observability_gap.ingress_shield_degraded`
- отключение или обход edge/perimeter policy
- fallback mode на front-door/ingress gateway

## Диагностика (строго по шагам)
1. Определить, какой компонент деградировал:
   - reverse proxy;
   - ingress gateway;
   - WAF;
   - cloud edge policy.
2. Проверить:
   - `failure_mode`
   - `fallback_mode`
   - `current_rps`
   - affected `endpoint`
3. Оценить, осталась ли система internet-exposed без perimeter protection.
4. Проверить, не идут ли параллельно `ddos_suspected` или overload/gap события.

## Ремедиация (строго по шагам)
1. Восстановить shield policy или вернуть healthy edge component.
2. Если это невозможно быстро, перевести внешний ingress в controlled degraded mode.
3. Подтвердить, что public traffic не идёт напрямую в `art-core` без защиты.
4. После восстановления прогнать hostile ingress smoke.

## Evidence (что приложить)
- `shield_component`
- `endpoint`
- `failure_mode`
- `fallback_mode`
- `current_rps`
- `trace_id`
- конфигурационный diff shield policy

## Postmortem checklist
- Почему shield деградировал?
- Был ли bypass path в `art-core`?
- Нужен ли более жёсткий release blocker?
- Нужны ли дополнительные smoke/chaos тесты для front-door?
