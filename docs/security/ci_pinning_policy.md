# CI pinning policy

- Все actions закрепляются на commit SHA.
- Запрещены `@v*`, `@main`, `@master`.
- Запрещены удалённые composite actions.
- Разрешены только локальные composite actions `./.github/actions/...`.
- `uses: docker://...` запрещён.
