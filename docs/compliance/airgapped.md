# Airgapped profile

## offline packs update
1. доставка архива packs
2. проверка подписи
3. проверка hash
4. ручная установка
5. version check (compatibility)
6. smoke-check

Процедура выполняется только в этом порядке. Пропуск шага или изменение порядка запрещены.

Подробности шагов:
- доставка архива packs: только через approved offline media;
- проверка подписи: verify по `signature + certificate (.pem) + OIDC issuer + certificate identity regexp`;
- проверка hash: сверка с `checksums.txt`;
- ручная установка: только после успешных verify и checksum;
- version check: профиль, pack version и target runtime должны быть совместимы;
- smoke-check: минимальный импорт и запуск без `observability_gap.profile_violation`.

## signature keys
- Статический `cosign.pub` для production baseline не используется.
- Verify выполняется по `signature + certificate (.pem) + OIDC issuer + certificate identity regexp`.
- Канонический путь политики trust-material в репозитории: `docs/security/keys/README.md`.
- Канонические runtime trust artifacts в release bundle: `*.sig`, `*.pem`, `checksums.txt`, `provenance.attestation.json`.
- Ротация signing baseline определяется release workflow и provenance policy.
- Установка packs и release artifacts без валидной подписи запрещена.
