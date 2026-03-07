# Политика Blameless Postmortem

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/incident_process.md`
- `docs/governance/postmortem_template.md`
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/full_line_by_line_audit_program_v0_2.md`

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
- должен быть указан `blast radius` и реальный пользовательский/бизнес-impact;
- должна быть зафиксирована цепочка `detection -> containment -> recovery`;
- должен быть выполнен multi-layer root-cause descent до корневой причины, а не только до верхнего симптома;
- должна быть оценена эффективность rollback/degraded mode, если они применялись;
- должен быть раздел counterfactuals: что могло обнаружить проблему раньше и какой guard предотвратил бы повторение;
- каждый follow-up должен иметь не только owner/due date, но и критерий верификации закрытия.

## Обязательные разделы postmortem-документа

Postmortem считается полным только если содержит:
- `impact`
- `blast radius`
- `timeline`
- `detection and containment`
- `root cause`
- `contributing factors`
- `degraded mode and rollback`
- `what went well`
- `what went wrong`
- `counterfactuals`
- `actions`
- `verification plan`
- `evidence`
- `owner follow-ups`

## Критерий актуальности

Документ считается актуальным только если:

- указано, для каких severity postmortem обязателен;
- указаны сроки;
- указана обязательность owner follow-ups;
- зафиксирован blameless principle;
- template требует hostile/adversarial анализ и root-cause descent;
- follow-ups имеют проверяемый критерий закрытия.
