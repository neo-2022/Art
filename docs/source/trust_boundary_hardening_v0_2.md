# Trust Boundary Hardening v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Назначение
Этот документ задаёт обязательную модель доверительных границ (trust boundary, граница доверия) для проекта.

Его задача — жёстко отделить:
- данные, которым система имеет право доверять;
- данные, которые разрешено учитывать только как недоверенные внешние входы;
- поля, которые не имеют права управлять ролями, режимами, scope-доступом, аудитом и безопасными действиями, если они пришли из недоверенного клиента.

## Проблема
Без жёсткой trust boundary система начинает верить заголовкам, параметрам и контексту, который может подделать клиент, прокси, злоумышленник или ошибочный интегратор.

Это приводит к самым опасным типам дефекта:
- подмена `actor_role`;
- подмена `mcp_mode`;
- подмена `access_scope`;
- ложный `client_ip` через `X-Forwarded-For`;
- ложный audit context;
- некорректные решения в `ActionRequest` и `ActionResult`;
- разрушение доказательной силы audit trail.

## Обязательный закон
1. Привилегированный контекст не может приходить напрямую из недоверенного клиента.
2. Единственный допустимый источник привилегированного actor-context — доверенный auth / edge / relay слой.
3. Недоверенные входящие заголовки фиксируются как данные наблюдения, но не как основание для security-решений.
4. Если источник actor-context не доказан, система обязана перейти в fail-closed режим.
5. Любое нарушение trust boundary порождает `observability_gap.trust_boundary_violation`.

## Канонический actor context
Ключевой термин этого контура: `trusted actor context` — только доказанный и доверенный источник actor/role/scope имеет право управлять privileged runtime path.

Привилегированный actor context включает:
- `actor_id`
- `actor_role`
- `mcp_mode`
- `access_scope`
- `tenant_id` (если применимо)
- `approval_actor`
- `auth_subject`
- `session_id`
- `trusted_client_ip`

## Разрешённые источники
### Доверенные источники
- локальный системный контур Core;
- доверенный auth gateway;
- доверенный relay/bridge после явной валидации;
- mTLS-идентифицированный Agent / service identity;
- подписанный internal service token с проверенным issuer.

### Недоверенные источники
- прямые пользовательские HTTP заголовки;
- браузерные заголовки без trusted edge;
- произвольный `X-Forwarded-For`;
- произвольный `X-Actor-Role`;
- произвольный `X-MCP-Mode`;
- произвольный `X-Access-Scope`;
- параметры URL, тело запроса и query как источник security-policy context.

## Правила обработки заголовков
### `x-actor-role`
- не принимается как источник роли из внешнего клиента;
- допускается только после явной трансформации доверенным auth/edge слоем;
- в противном случае игнорируется и фиксируется как нарушение trust boundary.

### `x-mcp-mode`
- не принимается из внешнего клиента;
- runtime режим задаётся доверенной policy-конфигурацией или доверенным admin path.

### `x-access-scope`
- не принимается из внешнего клиента;
- вычисляется на стороне доверенного auth/policy слоя.

### `x-forwarded-for`
- не принимается без списка доверенных прокси;
- используется только если:
  - запрос пришёл от доверенного proxy peer;
  - proxy chain валидирована;
  - правило chain parsing и sanitization зафиксировано.
- в остальных случаях `client_ip` = peer address или `unknown`.

### `user-agent`
- допускается только как диагностическое поле;
- не влияет на trust decisions;
- проходит privacy/redaction policy.

## Fail-closed поведение
Если trust boundary не доказана, система обязана:
- отклонить security-чувствительное действие;
- не повышать привилегии;
- не использовать недоверенные поля как audit truth;
- сгенерировать `observability_gap.trust_boundary_violation`;
- сохранить trace/evidence для расследования.

## Отрицательные сценарии (negative-path)
Обязательные сценарии проверки:
1. Клиент подменяет `x-actor-role=admin`.
2. Клиент подменяет `x-mcp-mode=full_admin`.
3. Клиент подменяет `x-access-scope=*`.
4. Клиент подменяет `X-Forwarded-For` при прямом запросе.
5. Trusted proxy выключен, а сервис получает запрос напрямую.
6. Relay не может доказать identity upstream.
7. Security-sensitive action приходит без verified actor context.

## Required evidence
При закрытии trust-boundary remediation должны существовать:
- integration tests на spoofed headers;
- trusted proxy / trusted relay matrix;
- audit evidence, что spoofed context не повышает привилегии;
- gap event evidence для нарушения trust boundary;
- release blocker policy для internet-exposed и partner-exposed профилей.

## Checklist mapping
- Stage 15 — RBAC / audit / actor context
- Stage 24 — release blocker и go/no-go
- Stage 33 — secure actions protocol
- Stage 37 — Linux/internet-exposed runtime hardening

## Статус
- Статус: `ACTIVE`
- Роль: `MANDATORY_PROTECTIVE_CONTOUR`
