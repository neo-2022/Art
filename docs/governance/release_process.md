# Release process

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/release/release_process.md`
- `docs/release/versioning.md`
- `RELEASE_CHECKLIST.md`
- `docs/ops/go_no_go_template.md`
- `docs/governance/release_decisions/latest_go_no_go.md`

## Versioning
- Версионирование строго по `SemVer`.
- Допустимые формы:
  - stable: `vMAJOR.MINOR.PATCH`
  - release candidate: `vMAJOR.MINOR.PATCH-rc.N`
  - hotfix: следующий PATCH на базе stable
- Production rollout запрещён без signed tag и согласованного `GO/NO-GO`.

## Changelog
- `CHANGELOG.md` обязателен до релизного тега.
- Запись в changelog обязана содержать:
  - что изменено;
  - риск/совместимость;
  - migration/rollback impact;
  - ссылку на evidence, если изменение критично для runtime/security.

## Типы релизов
- `candidate`: допускается только как production-candidate validation, не считается финальным production release.
- `stable`: допускается только после signed tag, published artifacts, `GO`, smoke-check и watch window.
- `hotfix`: проходит тот же release contour, но с отдельно зафиксированным rollback baseline.

## Обязательные pre-release условия
- все required CI gates зелёные;
- релевантные checklist stages не содержат открытых blockers;
- собраны release artifacts;
- заполнен и подписан `GO/NO-GO` sheet;
- evidence ledger и release metadata обновлены;
- rollback path подтверждён на текущем baseline.

## Обязательные release artifacts
- signed tag;
- release notes;
- `checksums.txt`;
- SBOM;
- provenance bundle;
- runtime compatibility note;
- ссылки на evidence artifacts.

## Release steps
1. Freeze целевого baseline и запретить неучтённые изменения.
2. Подготовить release PR: `CHANGELOG`, `RELEASE_CHECKLIST`, release evidence, compatibility notes.
3. Прогнать required gates, release regression и signing verification.
4. Заполнить `GO/NO-GO` decision sheet на текущий commit/tag candidate.
5. Создать signed tag через CI.
6. Опубликовать GitHub Release и обязательные артефакты.
7. Выполнить post-release smoke-check на заявленном production scope.
8. Открыть watch window и следить за divergence/error budget/backlog/runtime regressions.

## Smoke-check после релиза
После публикации релиза обязательно подтвердить:
- доступность основных runtime surfaces;
- snapshot/stream consistency;
- отсутствие active divergence incidents;
- отсутствие regressions на execute-gated платформах текущего release scope.

## Rollback
- rollback выполняется только до последнего подтверждённого stable baseline;
- rollback обязан иметь:
  - точный tag/commit;
  - команду/процедуру;
  - post-rollback smoke-check;
  - owner;
  - RTO expectation.
- после rollback обязательно обновляются evidence, release decision record и incident/postmortem trail.

## Запреты
- локальный ручной релиз вне CI запрещён;
- tag без provenance/checksums/SBOM запрещён;
- stable release при незаполненном `GO/NO-GO` запрещён;
- release считается незавершённым, если post-release smoke-check или watch window выявили regression.
