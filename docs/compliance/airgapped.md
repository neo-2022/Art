# Airgapped profile

## offline packs update
1. доставка архива packs
2. проверка подписи
3. проверка hash
4. ручная установка
5. version check (compatibility)
6. smoke-check

## signature keys
- Статический `cosign.pub` для production baseline не используется.
- Verify выполняется по `signature + certificate (.pem) + OIDC issuer + certificate identity regexp`.
- Ротация signing baseline определяется release workflow и provenance policy.
- Установка packs и release artifacts без валидной подписи запрещена.
