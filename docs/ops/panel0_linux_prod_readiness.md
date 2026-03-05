# Panel0 Linux Prod Readiness

Документ фиксирует Linux-only критерии готовности Panel0 перед выкладкой.

## Область

- Поддерживаемая ОС: Linux.
- Браузерный рантайм: Chromium/Chrome в headless режиме.
- Проверяется только Stage16 (Panel0 bootstrap/fallback/backlog/recovery).

## Обязательный прогон

Команда:

```bash
bash scripts/tests/panel0_linux_prod_readiness.sh
```

Сценарии, которые должны пройти:

1. `Console UP`:
   - `GET /` открывает `/console` без fallback.
   - `observability_gap.console_boot_failed` не увеличивается.
2. `Console HTTP error`:
   - `GET /` уходит в `/panel0/`.
   - событие появляется с `reason_type=http_error`.
3. `Console slow timeout`:
   - fallback срабатывает за 5 секунд.
   - событие появляется с `reason_type=timeout`.
4. `Hotkey Ctrl+Shift+P`:
   - открывает `/panel0/`.
   - не создаёт новый `console_boot_failed`.
5. `Ingest DOWN -> backlog -> recovery`:
   - при недоступном ingest событие уходит в backlog.
   - после восстановления ingest backlog очищается и событие публикуется.
6. `Core DOWN + Console DOWN`:
   - `/panel0/` остаётся доступной через SW cache.
   - отображается `Core недоступен`.
   - после восстановления Core placeholder скрывается автоматически.

## Наблюдаемость и алерты

Перед выкладкой убедиться:

- в `/api/v1/snapshot` и `/api/v1/stream` видны события `observability_gap.console_boot_failed`;
- поле `details.reason_type` всегда нормализовано (`network_error|http_error|timeout|runtime_crash`);
- `details.build_id` соответствует deploy build id;
- `details.trace_id` присутствует.

Порог алерта для Linux prod:

- `observability_gap.console_boot_failed` > 5 событий за 5 минут на инстанс -> investigate и блокировка дальнейшего раската.

## Canary и rollback

Canary-порядок для Linux:

1. Выложить новую версию на 1 инстанс.
2. Выполнить `scripts/tests/panel0_linux_prod_readiness.sh` на canary.
3. Проверить отсутствие всплеска `console_boot_failed` выше порога.
4. Только после этого расширять rollout.

Rollback-правило:

- если порог превышен или сценарий readiness упал — откат на предыдущий tag и повторный прогон readiness на откатанной версии.
