# Политика Blameless Postmortem

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/incident_process.md`
- `docs/governance/postmortem_template.md`

## Назначение

Postmortem обязателен для восстановления управляемости и накопления знания.  
Он не используется для поиска виноватого и не заменяет remediation plan.

## Когда postmortem обязателен

- после каждого `SEV0`;
- после каждого `SEV1`;
- после инцидента, который повторился;
- после incident, приведшего к изменению policy, runbook, contracts или release path.

## Сроки

- draft: не позднее `72 часов` после инцидента;
- publication-ready версия: после согласования owner follow-ups;
- follow-up review: до закрытия всех action items.

## Обязательные требования

- postmortem должен быть blameless;
- у каждого follow-up должен быть owner и due date;
- в документе должны быть evidence и timeline;
- root cause не может ограничиваться формулировкой "человеческая ошибка";
- должны быть зафиксированы как удачные действия, так и провалы процесса.

## Критерий актуальности

Документ считается актуальным только если:

- указано, для каких severity postmortem обязателен;
- указаны сроки;
- указана обязательность owner follow-ups;
- зафиксирован blameless principle.
