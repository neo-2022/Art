# PII/Secret filter

Фильтрация выполняется в pre-write фазе до записи в audit.

Применяется к:
- `params` из `actions/execute`
- `client_ip`
- `user_agent`
- контекстным полям audit

Правила redaction:
- секреты и токены маскируются (`***redacted***`)
- при фактическом redaction генерируется событие `privacy.redaction_applied`

