A) Полный запрет опциональности:
# CHECKLIST 15 — Actions/Audit/RBAC/PII
Файл: CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
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

- [x] **1. Сделать:** Реализовать RBAC роли `viewer` / `operator` / `admin` и запреты по ролям.
  - [x] Роли фиксированы (ровно три): `viewer`, `operator`, `admin`
  - [x] Матрица доступа фиксирована и реализована (endpoint → роль → allow/deny):
    - [x] `GET /api/v1/snapshot`: viewer=allow, operator=allow, admin=allow
    - [x] `GET /api/v1/stream`: viewer=allow, operator=allow, admin=allow
    - [x] `GET /api/v1/incidents`: viewer=allow, operator=allow, admin=allow
    - [x] `POST /api/v1/incidents/{id}/ack`: viewer=deny, operator=allow, admin=allow
    - [x] `POST /api/v1/incidents/{id}/resolve`: viewer=deny, operator=allow, admin=allow
    - [x] `POST /api/v1/actions/execute`: viewer=deny, operator=allow, admin=allow
    - [x] `GET /api/v1/audit`: viewer=deny, operator=deny, admin=allow
  - [x] Неизвестная роль трактуется как deny (fail closed)
  - [x] **Проверка (pass/fail):** integration tests матрицы доступа существуют и подтверждают allow/deny для каждого endpoint/роли.

- [x] **2. Сделать:** Реализовать runtime enforcement MCP режимов для Actions (поведение детерминировано).
  - [x] MCP режимы ровно три: `read_only`, `limited_actions`, `full_admin`
  - [x] `read_only`: `POST /api/v1/actions/execute` всегда deny (независимо от роли)
  - [x] `limited_actions`: разрешён только allowlist действий (перечень фиксирован и лежит в конфиге)
  - [x] `full_admin`: разрешены все действия для ролей operator/admin согласно RBAC (шаг 1)
  - [x] Любое deny по MCP режиму генерирует `security.access_denied` (шаг 4)
  - [x] **Проверка (pass/fail):** integration tests переключают MCP режимы и подтверждают:
    - [x] read_only блокирует actions/execute
    - [x] limited_actions блокирует действие вне allowlist
    - [x] full_admin пропускает действие по RBAC.

- [x] **3. Сделать:** Реализовать audit записи для Actions и критичных операций (append-only), включая `client_ip` и `user_agent` (после фильтрации).
  - [x] AuditEntry пишется для каждого вызова `POST /api/v1/actions/execute` (успех и отказ)
  - [x] AuditEntry пишется для `POST /api/v1/incidents/{id}/ack` и `POST /api/v1/incidents/{id}/resolve` (успех и отказ)
  - [x] AuditEntry содержит фиксированный минимум полей:
    - [x] `timestamp`
    - [x] `actor_id` (идентификатор субъекта)
    - [x] `actor_role` (viewer/operator/admin)
    - [x] `mcp_mode` (read_only/limited_actions/full_admin)
    - [x] `action` (строка)
    - [x] `target` (строка)
    - [x] `result` (enum: success|denied|error)
    - [x] `trace_id`
    - [x] `evidence_ref` (строка или `none`)
    - [x] `client_ip` (строка; допускается только в нормализованном/анонимизированном виде после PII filter; шаг 5)
    - [x] `user_agent` (строка; допускается только после PII/secret filter; шаг 5)
  - [x] `client_ip` хранится только в нормализованной форме:
    - [x] IPv4: обнуление последнего октета (например `203.0.113.0`)
    - [x] IPv6: обнуление последних 80 бит (префикс /48)
  - [x] `user_agent` хранится как строка max 256 символов после фильтрации; лишнее обрезается
  - [x] **Проверка (pass/fail):** integration test выполняет action и читает audit запись, подтверждая наличие и корректность всех перечисленных полей, включая `client_ip` и `user_agent` в нормализованном виде.

- [x] **4. Сделать:** Реализовать событие `security.access_denied` при любой попытке запрещённого действия (RBAC или MCP режим).
  - [x] `security.access_denied` генерируется при любом deny:
    - [x] deny по роли (RBAC)
    - [x] deny по MCP режиму (read_only/limited_actions)
  - [x] Событие попадает в snapshot/stream
  - [x] Событие содержит `what/where/why/evidence/actions` и `trace_id`
  - [x] evidence_min содержит:
    - [x] endpoint
    - [x] actor_role
    - [x] mcp_mode
    - [x] action (если применимо)
    - [x] reason (строка: rbac_denied|mcp_denied)
  - [x] `actions.action_ref` указывает на конкретный runbook: `docs/runbooks/access_denied.md`
  - [x] **Проверка (pass/fail):** integration test вызывает запрещённый endpoint и проверяет:
    - [x] HTTP deny (403)
    - [x] наличие `security.access_denied` в snapshot/stream
    - [x] наличие `action_ref=docs/runbooks/access_denied.md`.

- [x] **5. Сделать:** Реализовать PII/secret filtering ДО записи в audit (pre-write) и обеспечить генерацию `privacy.redaction_applied` при фактическом редактировании данных.
  - [x] Фильтрация применяется к:
    - [x] params для `actions/execute`
    - [x] `client_ip`
    - [x] `user_agent`
    - [x] любым контекстным полям, которые попадают в audit (`target`, `evidence_ref`, дополнительные метаданные)
  - [x] Политика фильтрации использует конфиг redaction rules (Stage 02)
  - [x] Любой секрет/PII в params должен быть маскирован/удалён ДО записи AuditEntry
  - [x] При фактическом изменении данных фильтром генерируется `privacy.redaction_applied` и оно попадает в snapshot/stream
  - [x] **Проверка (pass/fail):** security test инжектит секрет в params и проверяет:
    - [x] в audit отсутствует исходный секрет
    - [x] присутствует след фильтрации (маска/удаление)
    - [x] присутствует событие `privacy.redaction_applied`.

- [x] **6. Сделать:** Реализовать audit append-only immutability test (update/delete запрещены).
  - [x] Попытка изменить существующую audit запись отклоняется (fail)
  - [x] Попытка удалить audit запись отклоняется (fail)
  - [x] Audit записи связаны hash-chain (`prev_hash`/`entry_hash`), доступен `GET /api/v1/audit/verify` (admin-only)
  - [x] Тест проверяет, что количество записей не уменьшается и содержимое старых записей не меняется
  - [x] Тест tamper detection: ручное изменение старой записи приводит к `audit_chain_broken`
  - [x] **Проверка (pass/fail):** integration test “audit immutability” зелёный и подтверждает блокировку update/delete.

## Документация (RU)
- [x] docs/core/actions.md
- [x] docs/core/audit.md
- [x] docs/security/rbac.md
- [x] docs/security/pii_secret_filter.md
- [x] docs/security/mcp_modes_runtime.md
- [x] docs/runbooks/access_denied.md

## Тестирование
- [x] integration: RBAC матрица endpoint→роль (шаг 1)
- [x] integration: MCP runtime enforcement (read_only/limited_actions/full_admin) (шаг 2)
- [x] integration: audit fields include client_ip/user_agent (нормализовано) (шаг 3)
- [x] integration: access_denied → 403 + `security.access_denied` в snapshot/stream (шаг 4)
- [x] security: secret injection → pre-write filter + `privacy.redaction_applied` (шаг 5)
- [x] integration: audit immutability (append-only) (шаг 6)
- [x] integration: audit hash-chain verify (`/api/v1/audit/verify`) + tamper detection (шаг 6)

## CI gate
- [x] CI job `actions-audit-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `stage15-docs-gate` существует и запускается на PR в main
- [x] `stage15-docs-gate` запускает `scripts/ci/check_actions_stage15_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/security/rbac.md` содержит `viewer` и `operator` и `admin`
    - [x] `docs/security/mcp_modes_runtime.md` содержит `read_only` и `limited_actions` и `full_admin`
    - [x] `docs/core/audit.md` содержит `client_ip` и `user_agent` и `append-only`
    - [x] `docs/security/pii_secret_filter.md` содержит `pre-write` и `redaction`
    - [x] `docs/runbooks/access_denied.md` содержит `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] RBAC roles и матрица доступа реализованы и покрыты integration tests.
- [x] MCP runtime enforcement реализован и покрыт tests.
- [x] AuditEntry содержит поля (включая нормализованные `client_ip` и `user_agent`) и пишется для критичных операций.
- [x] `security.access_denied` генерируется и видим в snapshot/stream; есть runbook.
- [x] PII/secret filtering применяется ДО записи в audit; `privacy.redaction_applied` генерируется при фактическом редактировании.
- [x] Audit append-only + hash-chain immutability tests зелёные.
- [x] CI gate Stage 15 зелёный.
