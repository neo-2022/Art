# TLS rotation

## Назначение
Этот документ описывает текущий рабочий baseline ротации TLS и отдельно фиксирует границу между:
- тем, что уже materialized;
- и тем, что ещё нельзя выдавать за реализованное.

## Текущее фактическое состояние
Сейчас в `art-core`:
- `SIGHUP` выполняет runtime-hook;
- smoke уже доказывает, что активный stream не рвётся после `SIGHUP`;
- но **hot-reload самого TLS-контекста по `SIGHUP` ещё не materialized**.
- при невалидном TLS bootstrap `Core` стартует по принципу fail closed и пишет
  `observability_gap.tls_config_invalid` в persisted startup backlog, который публикуется в
  snapshot/stream на следующем успешном старте.

Поэтому честный безопасный путь ротации сегодня такой:
1. Обновить `cert/key`.
2. Выполнить controlled restart `art-core`.
3. Проверить health и stream.

Это важно фиксировать прямо, чтобы документация не обещала больше, чем делает runtime.

## Smoke-проверка текущего baseline
Что мы обязаны доказывать уже сейчас:
- runtime-hook `SIGHUP` не убивает процесс;
- активное stream-соединение не рвётся;
- после controlled restart сервис поднимается на актуальном TLS baseline.

## Runtime smoke
Команда:

```bash
bash scripts/tests/ops_stage23_smoke.sh
```

Что именно сейчас проверяет smoke:
- live DR restore сценарий на реальном `art-core`;
- что после `SIGHUP` runtime-hook Core живой;
- что удерживаемое `/api/v1/stream` соединение не рвётся.
- отдельный induced runtime smoke `scripts/tests/tls_config_invalid_runtime.sh`
  доказывает fail-closed старт, persisted startup backlog и публикацию
  `observability_gap.tls_config_invalid` на следующем успешном старте.

## Что ещё не закрыто
Полный `stage23 step 2` будет считаться закрытым только тогда, когда `SIGHUP` сможет:
- реально перезагрузить TLS-контекст;
- без controlled restart;
- без разрыва активных stream/SSE соединений.

Пока этого нет, документ обязан оставаться честным и не выдавать runtime-hook за готовый hot-reload.

## Pass/fail
- `pass`: runtime-hook жив, stream survive подтверждён, controlled restart path описан корректно.
- `fail`: документация обещает hot-reload TLS, а runtime его не умеет; либо `SIGHUP`/stream survival не доказаны.
