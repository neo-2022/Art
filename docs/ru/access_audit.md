# RU access audit

Просмотр PII-инцидента фиксируется при `GET /api/v1/incidents/{id}`.
Обязательные поля записи: `timestamp`, `actor_id`, `actor_role`, `incident_id`, `client_ip`, `user_agent`.
Хранилище append-only.
