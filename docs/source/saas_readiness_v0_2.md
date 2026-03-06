# SaaS Readiness v0.2

Последняя актуализация: 2026-03-06

## Цель
Формализовать SaaS-ready архитектуру без расхождения API поведения с self-hosted.

## Модель
- tenant hierarchy: org/project/env
- control-plane/data-plane boundaries
- quotas/retention/compliance export

## Инварианты
- Tenant isolation обязательна.
- API parity для Console обязательна.
- Нарушения isolation логируются как observability_gap.
- Каждый доступ к evidence имеет audit trail.
- Retention/anonymization workflow обязателен для privacy compliance.

## Проверка
- unit tenant policy
- integration isolation and quotas
- integration tenant isolation proof suite (negative cross-tenant matrix + audit assertions)
- e2e parity scenarios
- compliance retention/anonymization scenarios

## Evidence SLA (фикс)
- оперативные данные evidence: 30 дней.
- evidence инцидентов: 90 дней.
- audit/compliance evidence: 365+ дней.
- при переходе в long-term retention PII анонимизируется автоматически.
- request-driven anonymization/removal: не позднее 72 часов.
