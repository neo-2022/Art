# CI pinning policy

- Все actions закрепляются на commit SHA.
- Запрещены `@v*`, `@main`, `@master`.
- Запрещены удалённые composite actions.
- Разрешены только локальные composite actions `./.github/actions/...`.
- `uses: docker://...` запрещён.
- Внешние CLI инструменты (`semgrep`, `gitleaks`, `osv-scanner`, `syft`, `cosign`) фиксируются по версии.
- Разрешённые источники загрузки инструментов: официальные GitHub Releases и официальные registries.
