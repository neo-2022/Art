# Panel0 (embedded аварийная панель)

## Маршруты и назначение

- `GET /` — bootstrap страница. Сначала пытается открыть Console, при неуспехе переводит пользователя в Panel0.
- `GET /panel0` и `GET /panel0/` — entrypoint аварийной панели.
- `GET /panel0/index.html`
- `GET /panel0/panel0.js`
- `GET /panel0/panel0.css`
- `GET /panel0/panel0_sw.js`
- `GET /panel0/favicon.ico`

Все ассеты Panel0 встроены в бинарник Core (embedded), runtime-чтения с файловой системы не используются.

## Авто-fallback

Порядок на `GET /` фиксирован:
1. Bootstrap проверяет доступность Console по `ART_CONSOLE_BASE_PATH`.
2. Ждёт ровно `5000ms`.
3. Если Console не стала доступна, выполняет переход на `/panel0` и фиксирует событие `observability_gap.console_boot_failed`.

Параметры:
- `ART_CONSOLE_BASE_PATH` — base path Console, default `/console`.
- Разрешён только относительный путь вида `/...` (запрещены `http(s)://`, `//`, `..`).

## Событие observability_gap.console_boot_failed

Событие создаётся только при реальном сбое загрузки Console, причины:
- `network_error`
- `http_error`
- `timeout`
- `runtime_crash`

Обязательные поля `evidence_min` (всегда присутствуют):
- `reason_type`
- `url`
- `http_status` (число или `null`)
- `error_text` (строка)
- `timeout_ms` (число или `null`)
- `build_id`
- `effective_profile_id`
- `trace_id`

Отправка:
- сначала попытка отправить в `POST /api/v1/ingest`;
- при недоступном Core событие уходит в browser outbox backlog;
- при восстановлении Core backlog доставляется в ingest.

## Поведение при Core DOWN + Console DOWN

- Panel0 открывается и остаётся доступной (embedded).
- При недоступности `/health` или `/api/v1/snapshot` (network error / `503`) показывается `Core недоступен`.
- После восстановления Core панель повторно опрашивает API и выходит из placeholder.
- Событие `observability_gap.console_boot_failed` не теряется: остаётся в backlog и доставляется позже.

## Hotkey

- Горячая клавиша: `Ctrl+Shift+P`.
- Действие: принудительно открыть `/panel0`.
- Важно: hotkey не создаёт `reason_type=hotkey` и не публикует `console_boot_failed` сам по себе.

## build_id

- Источник: `PANEL0_BUILD_ID`.
- Значение по умолчанию: `dev`.
- Отображается в верхней плашке Panel0 и входит в evidence `console_boot_failed`.

## Отображение observability_gap

- Все события с префиксом `observability_gap.` выделяются фиксированно:
  - иконка: `⚠`
  - цвет: `amber`
  - tooltip: `kind`, `what`, `where`, `why`, `action_ref`, `trace_id`
- В tooltip редактируются секреты/PII (`token`, `Authorization`, `cookie`, `password`, `secret` и т.п.).
