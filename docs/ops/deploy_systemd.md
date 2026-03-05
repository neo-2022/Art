# Deploy systemd

Используется `art-core.service` и `art-agent.service`.

## Core TLS

Core поддерживает TLS в бинарнике (rustls). Для включения TLS в unit-файле `art-core.service` задаются:

- `Environment=CORE_TLS_CERT_PATH=/etc/art/tls/fullchain.pem`
- `Environment=CORE_TLS_KEY_PATH=/etc/art/tls/privkey.pem`
- `Environment=CORE_PORT=7331`

Если `CORE_TLS_CERT_PATH`/`CORE_TLS_KEY_PATH` не заданы, Core запускается в plain HTTP.

## Ротация сертификатов

- Базовый безопасный путь: обновить cert/key и выполнить `systemctl restart art-core.service`.
- Сигнал `SIGHUP` в текущей версии выполняет runtime-hook и используется для smoke-проверок, но не делает hot-reload TLS-контекста.
