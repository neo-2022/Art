# Runbook: DDoS Suspected

## Сигналы
- `observability_gap.ddos_suspected`
- аномальный рост `current_rps` или `current_connections`
- массовые `429/503` при стабильной business-нагрузке
- всплеск по одному `source_key` или по группе внешних адресов

## Диагностика (строго по шагам)
1. Подтвердить, что всплеск не является ожидаемым business burst или тестовой активностью.
2. Проверить perimeter/ingress shield:
   - активен ли rate limit;
   - активен ли connection limit;
   - не перешёл ли shield в fallback mode.
3. Сопоставить всплеск с `tenant_id`, `endpoint`, `source_key` и upstream alarms.
4. Проверить, не деградировал ли сам ingress shield (`observability_gap.ingress_shield_degraded`).
5. Подтвердить, что `art-core` не остался единственной линией защиты.

## Ремедиация (строго по шагам)
1. Ужесточить edge/perimeter policy.
2. При необходимости ограничить внешний ingress до controlled degraded mode.
3. Для SaaS включить per-tenant abusive traffic isolation.
4. Сохранить evidence о мерах и времени применения.
5. После стабилизации вернуть policy только после подтверждения безопасного трафика.

## Evidence (что приложить)
- `endpoint`
- `source_key`
- `current_rps`
- `current_connections`
- `limit_name`
- `shield_mode`
- `trace_id`
- лог срабатывания ingress policy

## Postmortem checklist
- Был ли реально front-door shield активен?
- Отличали ли мы business burst от hostile burst?
- Хватило ли per-tenant isolation?
- Нужно ли усилить release blockers для internet-exposed профиля?
