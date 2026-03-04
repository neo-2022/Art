# Audit policy

Журнал действий immutable (неизменяемый), append-only.

Обязательные поля записи:
- timestamp
- actor
- action
- target
- result
- evidence_ref

Требования:
- хранение: не менее 1 года
- update/delete записей аудита запрещены
- все auto/manual/MCP actions логируются
