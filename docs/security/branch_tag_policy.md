# Branch and tag policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/governance/repo_protection_evidence.md`
- `.github/CODEOWNERS`

## Политика ветки `main`
- прямые коммиты в `main` запрещены;
- любые изменения попадают в `main` только через Pull Request;
- required status checks для `main` включены и являются блокирующими;
- required reviews для `main` включены, минимум `1`;
- CODEOWNERS включён и влияет на required reviews;
- force-push в `main` запрещён;
- удаление `main` запрещено;
- администраторы не обходят protection path (`enforce_admins=true`);
- merge в `main` запрещён, если любой required check не зелёный;
- merge в `main` запрещён, если коммиты не имеют статуса `Verified`.

## Verified commits only in main
- каждый коммит, попадающий в `main`, обязан отображаться в GitHub UI как `Verified`;
- merge блокируется, если хотя бы один коммит в merge path не `Verified`;
- это правило распространяется на merge commit, squash commit и rebase path.

## Required status checks для `main`
Точный список required status checks:
- `sdlc-gate`
- `sast`
- `sca`
- `license`
- `secrets`

Другие jobs могут существовать в CI, но обязательными branch protection checks для `main`
считается только этот фиксированный список, пока он не пересмотрен через checklist/process law.

## Tag and release policy
- релизные теги имеют формат `v*`;
- релизные теги считаются immutable: переписывание, удаление и повторное использование имени тега запрещены;
- release tag создаётся только через утверждённую release procedure, а не локальной ручной командой разработчика;
- release tag должен указывать на commit, прошедший required checks и review path;
- публикация release без соответствующего release tag запрещена.

## Enforcement baseline
- branch enforcement для `main` подтверждается GitHub branch protection;
- tag/release enforcement подтверждается release governance, CI release path и запретом локальных релизов;
- любое отклонение от этой политики считается security/process violation.
