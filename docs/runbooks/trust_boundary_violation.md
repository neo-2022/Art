# Runbook: trust_boundary_violation

## Symptoms
- В логе и snapshot/stream появляется `observability_gap.trust_boundary_violation`.
- Security-sensitive действие отклоняется без повышения привилегий.
- Audit фиксирует spoofed или неподтверждённый actor context.

## Diagnosis
1. Определить источник запроса и цепочку proxy/relay.
2. Проверить, был ли actor context получен от trusted source.
3. Проверить, какие заголовки/поля пытались управлять ролью, режимом или scope.
4. Проверить, не попал ли spoofed context в audit как будто это истина.
5. Убедиться, что система сработала по fail-closed policy.

## Mitigations
1. Немедленно отключить доверие к спорному ingress path.
2. Восстановить trusted proxy / auth gateway / relay chain.
3. Запретить использование spoofed headers в affected deployment profile.
4. Обновить trusted source allowlist и policy docs.
5. Проверить релизный профиль и `GO/NO-GO` evidence.

Краткие mitigations:
- убрать доверие к недоказанному источнику actor context;
- восстановить trusted path;
- перепроверить release profile и policy baseline.

## Verification
1. Повторить spoofed-header negative test.
2. Подтвердить, что `actor_role`, `mcp_mode`, `access_scope` не повышаются из недоверенного клиента.
3. Подтвердить наличие `observability_gap.trust_boundary_violation` и trace/evidence.
4. Подтвердить, что безопасные действия снова доступны только через trusted path.

Краткая verification:
- повторить hostile negative path;
- подтвердить fail-closed поведение;
- подтвердить, что trusted context снова работает как единственный источник истины.
