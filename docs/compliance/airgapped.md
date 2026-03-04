# Airgapped profile

## offline packs update
1. доставка архива packs
2. проверка подписи
3. проверка hash
4. ручная установка
5. version check (compatibility)
6. smoke-check

## signature keys
- Путь публичного ключа: `docs/security/keys/cosign.pub`
- Ротация ключа документирована и обязательна
- Установка packs без валидной подписи запрещена
