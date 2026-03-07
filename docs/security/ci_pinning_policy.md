# CI pinning policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/security_stage04.yml`
- `.github/workflows/release_stage04.yml`
- `scripts/ci/check_secure_sdlc_stage04.sh`

## Политика pinning
- Все GitHub Actions во всех workflow закрепляются только на commit SHA.
- Запрещены ссылки `@v*`, `@main`, `@master`.
- Удалённые composite actions запрещены.
- Разрешены только локальные composite actions из репозитория: `uses: ./.github/actions/...`.
- `uses: docker://...` запрещён.
- Если в будущем появляются локальные composite actions, все `uses:` внутри `action.yml` подчиняются тем же правилам pinning.

## Допустимые форматы `uses:`
- `owner/repo@<40-hex-sha>`
- `./.github/actions/<name>`

Все остальные форматы считаются нарушением supply-chain policy.

## Внешние инструменты
- Внешние CLI инструменты (`semgrep`, `gitleaks`, `osv-scanner`, `syft`, `cosign`) фиксируются по версии.
- Загрузка таких инструментов допускается только из:
  - официальных GitHub Releases;
  - официальных registries;
  - официальных package indexes, если это зафиксировано в workflow.
- Использование `latest` для security/build tooling запрещено.

## Enforcement
- Политика проверяется скриптом `scripts/ci/check_secure_sdlc_stage04.sh`.
- Скрипт обязан валить CI при любом нарушении pinning:
  - в `.github/workflows/*.yml`;
  - внутри `.github/actions/**/action.yml`, если такие actions появятся.
