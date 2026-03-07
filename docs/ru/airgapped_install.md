# RU airgapped install

1. Проверить `checksums.txt`.
2. Проверить подписи через `cosign verify-blob` по `.sig + .pem + OIDC issuer + certificate identity regexp`.
3. Проверить `provenance.attestation.json` и совпадение `sha/subjects`.
4. Установить пакеты из локального репозитория.
5. Проверить профиль `ru` активен.
