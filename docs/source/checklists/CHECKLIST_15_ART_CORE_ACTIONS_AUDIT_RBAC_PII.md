A) Полный запрет опциональности:
# CHECKLIST 15 — Actions/Audit/RBAC/PII
Файл: CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение RBAC; изменение схемы audit; изменение PII/secret политики; изменение MCP режимов runtime

## Цель
Сделать Actions/Audit/RBAC/PII без двусмысленности: строгая матрица ролей viewer/operator/admin + enforcement MCP runtime; audit содержит client_ip и user_agent (после фильтрации); access_denied генерирует `security.access_denied`; PII/secret filtering применяется ДО записи в audit; audit append-only immutability test обязателен.

## Границы
Только Actions/Audit/RBAC/PII и runtime enforcement MCP режимов (read_only/limited_actions/full_admin).

## Зависимости
- CHECKLIST 14 — Stream/Snapshot v1 (SSE)
- CHECKLIST 02 — Privacy baseline (global) (redaction rules + privacy.redaction_applied)
- CHECKLIST 01 — Governance/SRE (MCP режимы как политика; audit policy)

## Шаги (строго линейно)

- [ ] **1. Сделать:** Реализовать RBAC роли `viewer` / `operator` / `admin` и запреты по ролям.
  - [ ] Роли фиксированы (ровно три): `viewer`, `operator`, `admin`
  - [ ] Матрица доступа фиксирована и реализована (endpoint → роль → allow/deny):
    - [ ] `GET /api/v1/snapshot`: viewer=allow, operator=allow, admin=allow
    - [ ] `GET /api/v1/stream`: viewer=allow, operator=allow, admin=allow
    - [ ] `GET /api/v1/incidents`: viewer=allow, operator=allow, admin=allow
    - [ ] `POST /api/v1/incidents/{id}/ack`: viewer=deny, operator=allow, admin=allow
    - [ ] `POST /api/v1/incidents/{id}/resolve`: viewer=deny, operator=allow, admin=allow
    - [ ] `POST /api/v1/actions/execute`: viewer=deny, operator=allow, admin=allow
    - [ ] `GET /api/v1/audit`: viewer=deny, operator=deny, admin=allow
  - [ ] Неизвестная роль трактуется как deny (fail closed)
  - [ ] **Проверка (pass/fail):** integration tests матрицы доступа существуют и подтверждают allow/deny для каждого endpoint/роли.

- [ ] **2. Сделать:** Реализовать runtime enforcement MCP режимов для Actions (поведение детерминировано).
  - [ ] MCP режимы ровно три: `read_only`, `limited_actions`, `full_admin`
  - [ ] `read_only`: `POST /api/v1/actions/execute` всегда deny (независимо от роли)
  - [ ] `limited_actions`: разрешён только allowlist действий (перечень фиксирован и лежит в конфиге)
  - [ ] `full_admin`: разрешены все действия для ролей operator/admin согласно RBAC (шаг 1)
  - [ ] Любое deny по MCP режиму генерирует `security.access_denied` (шаг 4)
  - [ ] **Проверка (pass/fail):** integration tests переключают MCP режимы и подтверждают:
    - [ ] read_only блокирует actions/execute
    - [ ] limited_actions блокирует действие вне allowlist
    - [ ] full_admin пропускает действие по RBAC.

- [ ] **3. Сделать:** Реализовать audit записи для Actions и критичных операций (append-only), включая `client_ip` и `user_agent` (после фильтрации).
  - [ ] AuditEntry пишется для каждого вызова `POST /api/v1/actions/execute` (успех и отказ)
  - [ ] AuditEntry пишется для `POST /api/v1/incidents/{id}/ack` и `POST /api/v1/incidents/{id}/resolve` (успех и отказ)
  - [ ] AuditEntry содержит фиксированный минимум полей:
    - [ ] `timestamp`
    - [ ] `actor_id` (идентификатор субъекта)
    - [ ] `actor_role` (viewer/operator/admin)
    - [ ] `mcp_mode` (read_only/limited_actions/full_admin)
    - [ ] `action` (строка)
    - [ ] `target` (строка)
    - [ ] `result` (enum: success|denied|error)
    - [ ] `trace_id`
    - [ ] `evidence_ref` (строка или `none`)
    - [ ] `client_ip` (строка; допускается только в нормализованном/анонимизированном виде после PII filter; шаг 5)
    - [ ] `user_agent` (строка; допускается только после PII/secret filter; шаг 5)
  - [ ] `client_ip` хранится только в нормализованной форме:
    - [ ] IPv4: обнуление последнего октета (например `203.0.113.0`)
    - [ ] IPv6: обнуление последних 80 бит (префикс /48)
  - [ ] `user_agent` хранится как строка max 256 символов после фильтрации; лишнее обрезается
  - [ ] **Проверка (pass/fail):** integration test выполняет action и читает audit запись, подтверждая наличие и корректность всех перечисленных полей, включая `client_ip` и `user_agent` в нормализованном виде.

- [ ] **4. Сделать:** Реализовать событие `security.access_denied` при любой попытке запрещённого действия (RBAC или MCP режим).
  - [ ] `security.access_denied` генерируется при любом deny:
    - [ ] deny по роли (RBAC)
    - [ ] deny по MCP режиму (read_only/limited_actions)
  - [ ] Событие попадает в snapshot/stream
  - [ ] Событие содержит `what/where/why/evidence/actions` и `trace_id`
  - [ ] evidence_min содержит:
    - [ ] endpoint
    - [ ] actor_role
    - [ ] mcp_mode
    - [ ] action (если применимо)
    - [ ] reason (строка: rbac_denied|mcp_denied)
  - [ ] `actions.action_ref` указывает на конкретный runbook: `docs/runbooks/access_denied.md`
  - [ ] **Проверка (pass/fail):** integration test вызывает запрещённый endpoint и проверяет:
    - [ ] HTTP deny (403)
    - [ ] наличие `security.access_denied` в snapshot/stream
    - [ ] наличие `action_ref=docs/runbooks/access_denied.md`.

- [ ] **5. Сделать:** Реализовать PII/secret filtering ДО записи в audit (pre-write) и обеспечить генерацию `privacy.redaction_applied` при фактическом редактировании данных.
  - [ ] Фильтрация применяется к:
    - [ ] params для `actions/execute`
    - [ ] `client_ip`
    - [ ] `user_agent`
    - [ ] любым контекстным полям, которые попадают в audit (`target`, `evidence_ref`, дополнительные метаданные)
  - [ ] Политика фильтрации использует конфиг redaction rules (Stage 02)
  - [ ] Любой секрет/PII в params должен быть маскирован/удалён ДО записи AuditEntry
  - [ ] При фактическом изменении данных фильтром генерируется `privacy.redaction_applied` и оно попадает в snapshot/stream
  - [ ] **Проверка (pass/fail):** security test инжектит секрет в params и проверяет:
    - [ ] в audit отсутствует исходный секрет
    - [ ] присутствует след фильтрации (маска/удаление)
    - [ ] присутствует событие `privacy.redaction_applied`.

- [ ] **6. Сделать:** Реализовать audit append-only immutability test (update/delete запрещены).
  - [ ] Попытка изменить существующую audit запись отклоняется (fail)
  - [ ] Попытка удалить audit запись отклоняется (fail)
  - [ ] Тест проверяет, что количество записей не уменьшается и содержимое старых записей не меняется
  - [ ] **Проверка (pass/fail):** integration test “audit immutability” зелёный и подтверждает блокировку update/delete.

## Документация (RU)
- [ ] docs/core/actions.md
- [ ] docs/core/audit.md
- [ ] docs/security/rbac.md
- [ ] docs/security/pii_secret_filter.md
- [ ] docs/security/mcp_modes_runtime.md
- [ ] docs/runbooks/access_denied.md

## Тестирование
- [ ] integration: RBAC матрица endpoint→роль (шаг 1)
- [ ] integration: MCP runtime enforcement (read_only/limited_actions/full_admin) (шаг 2)
- [ ] integration: audit fields include client_ip/user_agent (нормализовано) (шаг 3)
- [ ] integration: access_denied → 403 + `security.access_denied` в snapshot/stream (шаг 4)
- [ ] security: secret injection → pre-write filter + `privacy.redaction_applied` (шаг 5)
- [ ] integration: audit immutability (append-only) (шаг 6)

## CI gate
- [ ] CI job `actions-audit-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage15-docs-gate` существует и запускается на PR в main
- [ ] `stage15-docs-gate` запускает `scripts/ci/check_actions_stage15_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/security/rbac.md` содержит `viewer` и `operator` и `admin`
    - [ ] `docs/security/mcp_modes_runtime.md` содержит `read_only` и `limited_actions` и `full_admin`
    - [ ] `docs/core/audit.md` содержит `client_ip` и `user_agent` и `append-only`
    - [ ] `docs/security/pii_secret_filter.md` содержит `pre-write` и `redaction`
    - [ ] `docs/runbooks/access_denied.md` содержит `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] RBAC roles и матрица доступа реализованы и покрыты integration tests.
- [ ] MCP runtime enforcement реализован и покрыт tests.
- [ ] AuditEntry содержит поля (включая нормализованные `client_ip` и `user_agent`) и пишется для критичных операций.
- [ ] `security.access_denied` генерируется и видим в snapshot/stream; есть runbook.
- [ ] PII/secret filtering применяется ДО записи в audit; `privacy.redaction_applied` генерируется при фактическом редактировании.
- [ ] Audit append-only immutability test зелёный.
- [ ] CI gate Stage 15 зелёный.

