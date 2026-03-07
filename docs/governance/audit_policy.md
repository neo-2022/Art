# Audit policy

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
- `docs/governance/evidence_policy.md`
- `docs/privacy/redaction_policy.md`

## Базовый закон
Журнал действий immutable (неизменяемый), append-only.  
Изменение или удаление существующих audit entries запрещено.

## Что обязано попадать в аудит
Аудит обязателен для:
- manual UI/API actions;
- automatic rule-driven actions;
- MCP-команд;
- deny/forbidden actions;
- критичных incident operations (`ack`, `resolve`, release/rollback, policy-sensitive admin actions).

## Обязательные поля записи
- `timestamp`
- `actor`
- `action`
- `target`
- `result`
- `evidence_ref`

## Контракт поля `actor`
Поле `actor` обязано раскрываться не как свободный текст, а как связка:
- `actor_role` — роль (`viewer`, `operator`, `admin`, `system`, `agent`, `mcp`)
- `actor_id` — идентификатор субъекта или процесса
- `actor_origin` — источник (`ui`, `api`, `system`, `agent`, `mcp`)

Запрещено:
- писать только имя/ник без роли;
- писать только роль без идентификатора;
- смешивать человека и систему в одном неразделённом поле.

## Контракт результата
Поле `result` нормализуется минимум к:
- `success`
- `denied`
- `error`

## Privacy / redaction boundary
- PII/secret filtering применяется до записи в аудит.
- `client_ip`, `user_agent`, params и другие чувствительные поля допускаются только после pre-write redaction / нормализации.
- Если redaction реально изменила данные, генерируется `privacy.redaction_applied`.

## Срок хранения
- хранение: не менее 1 года
- точные retention overrides и региональные различия синхронизируются с privacy/compliance контуром

## Верификация и доказательства
- каждая критичная запись должна иметь `evidence_ref` или явно фиксированное значение `none`, если evidence неприменим
- цепочка аудита должна быть пригодна для дальнейшей verify/check path
- audit не считается достаточным, если в нём нельзя понять кто, что, куда, с каким результатом и на основании какого evidence действовал

## Запреты
- update/delete записей аудита запрещены
- логирование action без audit entry запрещено
- запись сырого PII/секретов в аудит запрещена
