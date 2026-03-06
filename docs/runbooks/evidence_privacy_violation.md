# Runbook: observability_gap.evidence_privacy_violation

## Symptoms
- Evidence выдан/сохранён с нарушением access_scope/redaction policy.
- Обнаружен доступ к PII вне разрешённой области.

## Diagnosis
1. Сверить actor_role, required_scope, effective_profile_id.
2. Проверить redaction_policy_id и retention.
3. Проверить audit trail по evidence_id.

## Resolution
1. Немедленно ограничить доступ и изолировать affected scope.
2. Выполнить redaction/removal/anonymization workflow.
3. Провести RCA и повторить privacy compliance tests.
