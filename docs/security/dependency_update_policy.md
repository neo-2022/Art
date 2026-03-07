# Политика обновления зависимостей

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/dependabot.yml`
- `.github/workflows/security_stage04.yml`
- `docs/security/sca_policy.md`
- `docs/security/ci_pinning_policy.md`

## Цель
Обновления зависимостей должны происходить контролируемо, через pull request, с теми же security gates, что и любой другой код. Автообновление не имеет права обходить review, CODEOWNERS, branch protection, SAST/SCA/license/secrets и требования reproducible build.

## Выбранный механизм
- Единственный разрешённый механизм автоматических PR-обновлений: `Dependabot`.
- Конфигурация хранится в `.github/dependabot.yml`.
- Поддерживаемые экосистемы для текущего репозитория:
  - `github-actions`
  - `cargo`
  - `npm` / `pnpm workspace`

## Базовые правила
- Обновления зависимостей допускаются только через PR.
- Прямые коммиты зависимостей в `main` запрещены.
- Автообновление не имеет права создавать release tag, пушить в `main` или обходить branch protection.
- Каждый PR с обновлением зависимостей проходит те же обязательные checks, что и обычный PR:
  - `sdlc-gate`
  - `sast`
  - `sca`
  - `license`
  - `secrets`
- PR с обновлением зависимостей не может считаться безопасным только потому, что его создал бот.

## Политика частоты и объёма
- Schedule: `weekly`.
- Dependabot обновляет только `main`.
- Для каждой экосистемы включён `open-pull-requests-limit`, чтобы бот не засыпал репозиторий шумом.
- Обновления группируются по экосистеме, а не создают десятки разрозненных PR без причины.
- Security updates не отключаются и не переводятся в ручной режим.

## Политика безопасного обновления
- Lockfile changes допускаются только как следствие PR-обновления зависимости.
- Обновление, которое меняет transitive dependency graph, обязано пройти:
  - SCA;
  - license checks;
  - reproducibility path;
  - targeted runtime/test path, если затронута соответствующая подсистема.
- Если обновление ломает pinned toolchain, build determinism, signing, SBOM или release verify, PR блокируется.
- Автоmerge dependency PR запрещён по умолчанию.

## Экосистемы

### GitHub Actions
- Все actions в workflow остаются pinned на commit SHA.
- Dependabot может поднимать PR на обновление SHA, но итоговый PR всё равно обязан пройти `security-stage04` и branch protection.
- Обновления `github-actions` не имеют права возвращать `@v*`, `@main`, `@master`.

### Cargo
- Источник истины: `Cargo.lock`.
- Обновление Rust crates идёт через Dependabot PR в корень репозитория.
- Любое изменение, ломающие `cargo deny`, лицензии или SCA policy, блокирует merge.

### npm / pnpm workspace
- Источник истины: `pnpm-lock.yaml`.
- Обновление workspace-пакетов идёт через Dependabot PR в корень репозитория.
- PR обязан пройти JS license summary и связанные tests/build checks, если они попадают в changed scope.

## Чего делать нельзя
- Обходить Dependabot ручным массовым bump без PR.
- Ослаблять required checks ради “быстрого security fix”.
- Принимать bot PR без review.
- Разрешать обновления из непроверенных registries или со снятием pinning policy.

## Эксплуатационный эффект
- Репозиторий не зависит от ручного и нерегулярного обновления зависимостей.
- Любой bump проходит тот же защитный контур, что и обычный код.
- Security updates не выпадают из процесса branch protection.

## Проверка
- Существует `.github/dependabot.yml` с экосистемами `github-actions`, `cargo`, `npm`.
- `docs/security/dependency_update_policy.md` явно содержит:
  - `Dependabot`
  - правило `PR-only`
  - требование прохождения security gates
  - weekly schedule
  - запрет auto-merge
