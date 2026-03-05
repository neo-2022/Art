# Console Boot Failed Runbook

Событие: `observability_gap.console_boot_failed`  
Компонент: `browser/panel0`  
Тип реакции: `log_only` (без авто-инцидента, но с обязательной диагностикой причины)

## Symptoms

- Пользователь открывает `GET /`, но основная Console не становится доступной.
- Через 5 секунд происходит auto-fallback на `GET /panel0`.
- В Panel0 отображается аварийная панель; при недоступном Core показывается `Core недоступен`.
- В snapshot/stream появляется событие `observability_gap.console_boot_failed` (или сначала копится в browser backlog и доставляется при восстановлении Core).

## Diagnosis

1. Проверить, что Core отдаёт bootstrap и Panel0-роуты:
   - `GET /`
   - `GET /panel0`
   - `GET /panel0/panel0.js`
   - `GET /panel0/panel0.css`
   - `GET /panel0/panel0_sw.js`
   - `GET /panel0/favicon.ico`
2. Проверить событие в `GET /api/v1/snapshot` или `GET /api/v1/stream`:
   - `kind = observability_gap.console_boot_failed`
   - `details.reason_type` в одном из значений: `network_error | http_error | timeout | runtime_crash`
3. Проверить обязательные поля evidence:
   - `reason_type`
   - `url`
   - `http_status` (число или `null`)
   - `error_text` (строка)
   - `timeout_ms` (число или `null`)
   - `build_id`
   - `effective_profile_id`
   - `trace_id`
4. Проверить конфиг bootstrap:
   - `ART_CONSOLE_BASE_PATH` корректен (относительный путь вида `/...`)
   - `PANEL0_BUILD_ID` установлен ожидаемо (или используется default `dev`)

## Resolution

1. Восстановить доступность Console по пути `ART_CONSOLE_BASE_PATH`:
   - устранить сетевую ошибку (`network_error`)
   - исправить HTTP ошибку (`http_error`)
   - исправить длительный старт/ready (`timeout`)
   - устранить JS boot crash (`runtime_crash`)
2. Подтвердить восстановление:
   - `GET /` больше не уходит в fallback после 5 секунд
   - Console открывается штатно
3. При наличии backlog в браузере:
   - открыть `GET /panel0` и дождаться доступности Core
   - убедиться, что backlog доставлен и событие видно в snapshot/stream
4. Зафиксировать причину и corrective action в postmortem/ops-журнале (если повторяется).
