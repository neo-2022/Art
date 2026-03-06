# DSR process

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/retention_matrix.md`
- `docs/governance/audit_policy.md`
- `docs/privacy/redaction_policy.md`

## Назначение

Этот документ фиксирует privacy-process для запросов субъекта данных:
- `export`
- `delete`
- `rectify`

## Идентификация субъекта запроса

Допустимые идентификаторы:
- `user_id`
- `email`
- `external_id`

Жёсткое правило:
- запрос не выполняется по свободному тексту без одного из поддержанных идентификаторов;
- совпадение должно быть воспроизводимо и auditable;
- ambiguity должна приводить к отказу или ручному уточнению, а не к “примерному совпадению”.

## 1. Export

Шаги:
1. принять запрос и зафиксировать идентификатор субъекта;
2. определить effective profile и policy restrictions;
3. собрать допустимый набор данных из разрешённых контуров;
4. применить privacy policy к export bundle;
5. выпустить export artifact;
6. записать audit record о факте экспорта.

Результат:
- субъект получает export только в пределах разрешённой policy;
- export не должен включать `secrets` и не должен нарушать redaction policy.

## 2. Delete

Шаги:
1. принять запрос;
2. определить, какие сущности подпадают под delete policy;
3. выполнить удаление в хранилищах, где delete разрешён;
4. не переписывать append-only audit;
5. зафиксировать completion artifact и audit record.

Жёсткое правило:
- удаление не должно нарушать append-only свойства audit;
- вместо редактирования audit задним числом privacy baseline требует pre-write redaction.

## 3. Rectify

Шаги:
1. принять запрос;
2. определить сущности, допускающие исправление;
3. создать корректирующую запись или безопасный update path;
4. зафиксировать audit trail изменения;
5. не переписывать append-only audit history.

## Правило append-only audit

`AuditEntry` append-only, не редактируется задним числом.

Это означает:
- audit не переписывается для удаления старой PII;
- PII/Secrets должны быть redacted pre-write до попадания в audit;
- DSR delete/rectify не могут использоваться как механизм ретроактивной чистки уже записанного сырого секрета — такой секрет не должен был туда попасть изначально.

## Связи с retention и audit policy

- retention определяется в `docs/privacy/retention_matrix.md`
- неизменяемость и состав audit определяются в `docs/governance/audit_policy.md`
- redaction baseline определяется в `docs/privacy/redaction_policy.md`

## Артефакты и доказательства

Каждый DSR flow должен иметь:
- request identifier
- subject identifier type
- execution outcome
- evidence artifact / export artifact / delete report
- audit reference

## Критерий актуальности

Документ считается актуальным только если:
- описаны шаги `export`, `delete`, `rectify`;
- перечислены допустимые идентификаторы субъекта;
- явно зафиксировано правило `AuditEntry append-only`;
- явно зафиксировано правило `PII/Secrets redacted pre-write`;
- есть ссылки на retention matrix и audit policy.
