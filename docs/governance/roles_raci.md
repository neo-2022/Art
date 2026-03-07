# RACI ролей Art

Source of truth:
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `.github/CODEOWNERS`

## Назначение

Этот документ фиксирует не только абстрактные роли, но и текущих ответственных, их зоны решения, правила замещения и RACI по ключевым областям проекта. Для Art это обязательный operational artifact: если роль не имеет ответственного, этап не считается управляемым.

## Правила

- У каждой роли должен быть `primary owner`.
- Для ролей `On-call`, `Security`, `Release` должен быть указан способ замещения.
- Один человек может совмещать несколько ролей, но это должно быть зафиксировано явно.
- При изменении состава ролей документ обновляется в том же PR, что и изменение процесса/доступов.

## Текущий состав ролей

| Роль | Primary owner | Backup / delegate | Основная зона ответственности | Decision rights | Канал эскалации |
|---|---|---|---|---|---|
| Owner | `@neo-2022` | временно не назначен; эскалация в release review | продуктовые решения, приоритеты, финальное принятие архитектурных компромиссов | утверждает roadmap, production go/no-go, исключения из правил | `docs/governance/oncall.md` |
| Maintainer | `@neo-2022` | временно не назначен; до назначения backup изменения ведутся только через review trail | поддержка репозитория, merge discipline, CI/CD, исправления регрессий | merge после PASS-gates, поддержка main, обновление обязательных артефактов | `docs/governance/oncall.md` |
| Reviewer | `@neo-2022` | дополнительный reviewer/witness: `@2art260679-rgb` | технический review, целостность чек-листов, контроль непротиворечивости docs/code/tests | блокирует merge при отсутствии evidence, возвращает этап в `[ ]` при формальном закрытии | PR review + `docs/governance/change_policy.md` |
| On-call | `@neo-2022` | handover по `docs/governance/oncall.md`; временный delegate фиксируется в handover log | реакция на инциденты, triage, коммуникация, запуск runbook | инициирует incident bridge, переводит severity, поднимает эскалацию | `docs/governance/oncall.md` |
| Security | `@neo-2022` | на период отсутствия выполняется через explicit review в security-change trail | secrets, supply-chain, vulnerability handling, signing/provenance | блокирует релиз при security-blocker, утверждает severity security incidents | `docs/governance/vulnerability_process.md` |
| Release | `@neo-2022` | release witness: `@2art260679-rgb` для PR approval / release evidence review | release checklist, changelog, tagging, rollback readiness, release evidence | утверждает candidate/stable release только после PASS всех gates | `docs/release/release_process.md` |

## Совмещение ролей и ограничения

Текущий проектный baseline допускает совмещение ролей `Owner`, `Maintainer`, `On-call`, `Security`, `Release` одним primary owner (`@neo-2022`) при соблюдении следующих ограничений:

- production release не считается готовым без review/evidence trail;
- reopening чек-листа имеет приоритет над “сохранением зелёного статуса”;
- все критические изменения обязаны оставлять артефакты в `docs/governance/evidence/`;
- если назначен временный delegate, он должен быть зафиксирован в handover/evidence.

## RACI по областям

Обозначения:
- `R` — выполняет работу
- `A` — несёт конечную ответственность
- `C` — консультируется
- `I` — информируется

| Область | Owner | Maintainer | Reviewer | On-call | Security | Release |
|---|---|---|---|---|---|---|
| Контракты API / Schema | A | R | C | I | C | I |
| Core / Agent / Browser релизы | A | R | C | I | C | R |
| Incident management | A | C | I | R | C | I |
| Vulnerability handling | A | I | I | I | R | I |
| Change / review process | A | R | R | I | C | C |
| Checklist truthfulness / reopening | A | R | R | I | C | I |
| Release evidence / provenance | A | R | C | I | C | R |
| Security gates / supply-chain | A | C | I | I | R | C |

## Правила замещения

- Если `On-call` недоступен, handover обязан назначить временного delegate и указать время начала/окончания замещения.
- Если `Release` недоступен во время релизного окна, релиз переносится; бесхозный релиз запрещён.
- Если `Security` недоступен и есть security-blocker, release запрещён до явной фиксации решения в evidence trail.

## Проверка актуальности

Документ считается актуальным только если одновременно выполняется следующее:

- перечислены все роли из `CHECKLIST_01`;
- у каждой роли есть `primary owner`;
- у operational roles есть способ замещения;
- RACI-таблица покрывает ключевые области проекта;
- ссылки на связанные governance/release документы не битые.
