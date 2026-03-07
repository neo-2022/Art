# Deploy systemd

Используется `art-core.service` и `art-agent.service`.

## Core TLS

Core поддерживает TLS в бинарнике (rustls). Для включения TLS в unit-файле `art-core.service` задаются:

- `Environment=CORE_TLS_CERT_PATH=/etc/art/tls/fullchain.pem`
- `Environment=CORE_TLS_KEY_PATH=/etc/art/tls/privkey.pem`
- `Environment=CORE_PORT=7331`
- `Environment=CORE_DB_PATH=/var/lib/art/core/core.sqlite3`
- `Environment=CORE_ANALYTICS_STATE_PATH=/var/lib/art/core/analytics.json`

Если `CORE_TLS_CERT_PATH`/`CORE_TLS_KEY_PATH` не заданы, Core запускается в plain HTTP.

## Core storage path

Для production systemd-развёртывания важно фиксировать не только TLS, но и явный runtime storage path.
Иначе backup/restore и DR drill начинают ссылаться на абстрактную БД, а не на реальный рабочий контур.

Минимальный baseline:
- `CORE_DB_PATH` указывает на рабочую SQLite `Art Core`;
- `CORE_ANALYTICS_STATE_PATH` указывает на sidecar-файл аналитики;
- backup/restore и DR drill обязаны ссылаться именно на этот `CORE_DB_PATH`.

## Ротация сертификатов

- Базовый безопасный путь: обновить cert/key и выполнить `systemctl restart art-core.service`.
- Сигнал `SIGHUP` в текущей версии выполняет runtime-hook и используется для smoke-проверок, но не делает hot-reload TLS-контекста.
