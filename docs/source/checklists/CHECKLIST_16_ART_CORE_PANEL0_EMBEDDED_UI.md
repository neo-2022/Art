A) Полный запрет опциональности:
# CHECKLIST 16 — Art Core Panel0 Embedded UI (auto-fallback v1)
Файл: CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение fallback-контракта `/`, изменение `/panel0/*` роутов, изменение evidence `observability_gap.console_boot_failed`

## Цель
Реализовать детерминированный аварийный вход в Panel0: `GET /` пытается открыть Console и при сбое за 5 секунд переводит в Panel0 с обязательной фиксацией `observability_gap.console_boot_failed`.

## Границы
- Только Art Core + embedded Panel0.
- REGART код не изменяется.
- Проверяются runtime-роуты, fallback-контракт, backlog-доставка события, docs и CI gate Stage16.

## Зависимости
- CHECKLIST 00 — MASTER
- CHECKLIST 14 — Stream/Snapshot
- CHECKLIST 15 — Actions/Audit/RBAC/PII

## Шаги (строго линейно)

- [x] **1. Сделать:** Встроить Panel0 assets в бинарник Core и отдать их через фиксированные роуты.
  - [x] `GET /panel0` и `GET /panel0/` отдают `index.html`
  - [x] `GET /panel0/index.html`
  - [x] `GET /panel0/panel0.js`
  - [x] `GET /panel0/panel0.css`
  - [x] `GET /panel0/panel0_sw.js`
  - [x] `GET /panel0/favicon.ico`
  - [x] Для каждого роута возвращается корректный `Content-Type`
  - [x] Runtime не читает panel0-ассеты с ФС
  - [x] **Проверка (pass/fail):** интеграционный тест `panel0_routes_serve_embedded_assets_with_content_types` + runtime gate `scripts/ci/check_panel0_stage16_runtime.sh`.

- [x] **2. Сделать:** Реализовать bootstrap на `GET /` с auto-fallback в Panel0.
  - [x] Источник Console path: env `ART_CONSOLE_BASE_PATH`, default `/console`
  - [x] Валидация `ART_CONSOLE_BASE_PATH`: только относительный путь `/...`, запрет `http(s)://`, `//`, `..`
  - [x] Timeout фиксирован: ровно `5000ms`
  - [x] При недоступности Console выполняется переход на `/panel0`
  - [x] **Проверка (pass/fail):** тест `root_route_serves_bootstrap_with_timeout_and_event_contract` + runtime gate проверяет контракт bootstrap.

- [x] **3. Сделать:** Фиксировать `observability_gap.console_boot_failed` с обязательным evidence и backlog доставкой.
  - [x] Причины fallback фиксированы: `network_error`, `http_error`, `timeout`, `runtime_crash`
  - [x] `evidence_min` включает поля: `reason_type`, `url`, `http_status`, `error_text`, `timeout_ms`, `build_id`, `effective_profile_id`, `trace_id`
  - [x] Нормализация evidence: `http_status`/`timeout_ms` как число или `null`, `error_text` как строка
  - [x] Если Core DOWN, событие сохраняется в browser backlog и отправляется после восстановления Core
  - [x] **Проверка (pass/fail):** runtime gate публикует `observability_gap.console_boot_failed` и подтверждает наличие в snapshot/stream с полным набором evidence.

- [x] **4. Сделать:** Зафиксировать поведение hotkey и core-down placeholder.
  - [x] `Ctrl+Shift+P` открывает `/panel0`
  - [x] hotkey не создаёт отдельный `reason_type` и не эмитит `console_boot_failed` без фактического падения Console
  - [x] При Core DOWN показывается placeholder `Core недоступен` (network error / HTTP code)
  - [x] При восстановлении Core panel автоматически перепроверяет API и выходит из placeholder
  - [x] **Проверка (pass/fail):** runtime/embedded проверки содержимого bootstrap/panel0.js + browser e2e для hotkey и placeholder.

- [x] **5. Сделать:** Обновить registry/runbook/docs под единый контракт Stage16.
  - [x] В `docs/governance/observability_gap_registry.md` добавлено `observability_gap.console_boot_failed`
  - [x] `owner_component=browser/panel0`, `incident_rule=log_only`, `action_ref=docs/runbooks/console_boot_failed.md`
  - [x] Создан `docs/runbooks/console_boot_failed.md` с разделами `Symptoms`, `Diagnosis`, `Resolution`
  - [x] Обновлён `docs/ui/panel0.md`: fallback, hotkey, env, Core DOWN + Console DOWN
  - [x] **Проверка (pass/fail):** `bash scripts/ci/check_panel0_stage16_docs.sh`.

## Документация (RU)
- [x] docs/ui/panel0.md
- [x] docs/ui/panel0_offline.md
- [x] docs/ui/panel0_sw_cache.md
- [x] docs/runbooks/console_boot_failed.md
- [x] docs/governance/observability_gap_registry.md

## Тестирование
- [x] e2e: gap highlight (историческое покрытие panel0-e2e)
- [x] e2e: core-down placeholder (историческое покрытие panel0-e2e + runtime markers)
- [x] e2e: offline cache и negative SW сценарии (историческое покрытие panel0-e2e)
- [x] e2e: auto-fallback при Console DOWN (5s timeout)
- [x] e2e: observability_gap.console_boot_failed появляется в snapshot/stream
- [x] e2e: hotkey Ctrl+Shift+P открывает Panel0
- [x] e2e: Core DOWN + Console DOWN -> core-down placeholder

## CI gate
- [x] `panel0-e2e` запускает `node --test test/panel0.e2e.test.js`
- [x] `stage16-docs-gate` запускает:
  - [x] `bash scripts/ci/check_panel0_stage16_docs.sh`
  - [x] `bash scripts/ci/check_panel0_stage16_runtime.sh`
- [x] Runtime gate проверяет `/`, `/panel0/*`, event-контракт `console_boot_failed`, snapshot/stream.

## DoD
- [x] Документация обновлена и непротиворечива (registry + runbook + panel0 docs).
- [x] Core отдаёт embedded `/panel0/*` без зависимости от ФС.
- [x] `GET /` реализует fallback Console -> Panel0 за 5 секунд.
- [x] Событие `observability_gap.console_boot_failed` проходит в snapshot/stream с обязательным evidence.
- [x] Горячая клавиша `Ctrl+Shift+P` открывает Panel0 и не создаёт искусственный `reason_type`.
- [x] CI Stage16 (docs + runtime) проходит.
