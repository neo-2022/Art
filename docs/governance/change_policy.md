# Политика Изменений

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `.github/CODEOWNERS`
- `.github/pull_request_template.md`
- `docs/governance/repo_protection_evidence.md`

## Базовые правила

- прямые коммиты в `main` запрещены;
- любые изменения проходят только через Pull Request;
- PR обязан ссылаться на релевантный этап программы или чек-лист;
- PR обязан содержать `Evidence`;
- merge без review запрещён.

## Обязательные требования к PR

Каждый PR обязан содержать:

- краткое описание изменения;
- причину изменения;
- способ проверки;
- evidence;
- ссылку на релевантный чек-лист или source-of-truth документ;
- явное указание, затронуты ли контракты, миграции, release steps или security policy.

## Требования к review

- минимум `1 reviewer` из `.github/CODEOWNERS` обязателен;
- review должен быть положительным и оставлен до merge;
- если PR затрагивает security, contracts, CI, release path или governance, review не может быть формальным "LGTM" без проверки evidence;
- self-approval запрещён, если branch protection или external review path доступны.

## Дополнительные требования к критичным изменениям

Для изменений, затрагивающих:

- contracts / schemas / OpenAPI;
- release pipeline;
- security / supply-chain;
- incident / audit / action policy;
- platform matrix;
- privacy / RU profile;

обязательны:

- явное описание риска;
- rollback path;
- ссылка на обновлённую документацию;
- актуальный evidence trail.

## Запрещено

- формально закрывать чек-лист без выполнения;
- обходить branch protection;
- менять канон без обновления зависимых документов;
- сливать PR без evidence;
- держать критическое изменение только в issue/comment без PR.

## Критерий актуальности

Документ считается актуальным только если:

- зафиксирован запрет прямых коммитов в `main`;
- зафиксированы требования к PR;
- явно указан минимум `1 reviewer` из `CODEOWNERS`;
- описаны правила для критичных изменений и evidence.
