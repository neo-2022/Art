A) Полный запрет опциональности:
# CHECKLIST 16 — Art Core Panel0 Embedded UI (auto-fallback v1)
Файл: CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение fallback-контракта `/`, изменение `/panel0/*` роутов, изменение evidence `observability_gap.console_boot_failed`
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

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

- [ ] **1. Сделать:** Встроить Panel0 assets в бинарник Core и отдать их через фиксированные роуты.
  - [ ] `GET /panel0` и `GET /panel0/` отдают `index.html`
  - [ ] `GET /panel0/index.html`
  - [ ] `GET /panel0/panel0.js`
  - [ ] `GET /panel0/panel0.css`
  - [ ] `GET /panel0/panel0_sw.js`
  - [ ] `GET /panel0/favicon.ico`
  - [ ] Для каждого роута возвращается корректный `Content-Type`
  - [ ] Runtime не читает panel0-ассеты с ФС
  - [ ] **Проверка (pass/fail):** интеграционный тест `panel0_routes_serve_embedded_assets_with_content_types` + runtime gate `scripts/ci/check_panel0_stage16_runtime.sh`.

- [ ] **2. Сделать:** Реализовать bootstrap на `GET /` с auto-fallback в Panel0.
  - [ ] Источник Console path: env `ART_CONSOLE_BASE_PATH`, default `/console`
  - [ ] Валидация `ART_CONSOLE_BASE_PATH`: только относительный путь `/...`, запрет `http(s)://`, `//`, `..`
  - [ ] Timeout фиксирован: ровно `5000ms`
  - [ ] При недоступности Console выполняется переход на `/panel0`
  - [ ] **Проверка (pass/fail):** тест `root_route_serves_bootstrap_with_timeout_and_event_contract` + runtime gate проверяет контракт bootstrap.

- [ ] **3. Сделать:** Фиксировать `observability_gap.console_boot_failed` с обязательным evidence и backlog доставкой.
  - [ ] Причины fallback фиксированы: `network_error`, `http_error`, `timeout`, `runtime_crash`
  - [ ] `evidence_min` включает поля: `reason_type`, `url`, `http_status`, `error_text`, `timeout_ms`, `build_id`, `effective_profile_id`, `trace_id`
  - [ ] Нормализация evidence: `http_status`/`timeout_ms` как число или `null`, `error_text` как строка
  - [ ] Если Core DOWN, событие сохраняется в browser backlog и отправляется после восстановления Core
  - [ ] **Проверка (pass/fail):** runtime gate публикует `observability_gap.console_boot_failed` и подтверждает наличие в snapshot/stream с полным набором evidence.

- [ ] **4. Сделать:** Зафиксировать поведение hotkey и core-down placeholder.
  - [ ] `Ctrl+Shift+P` открывает `/panel0`
  - [ ] hotkey не создаёт отдельный `reason_type` и не эмитит `console_boot_failed` без фактического падения Console
  - [ ] При Core DOWN показывается placeholder `Core недоступен` (network error / HTTP code)
  - [ ] Tier A i18n backport: EN default + runtime RU switch для статусов/tooltip
  - [ ] При восстановлении Core panel автоматически перепроверяет API и выходит из placeholder
  - [ ] **Проверка (pass/fail):** runtime/embedded проверки содержимого bootstrap/panel0.js + browser e2e для hotkey и placeholder.

- [ ] **5. Сделать:** Обновить registry/runbook/docs под единый контракт Stage16.
  - [ ] В `docs/governance/observability_gap_registry.md` добавлено `observability_gap.console_boot_failed`
  - [ ] `owner_component=browser/panel0`, `incident_rule=log_only`, `action_ref=docs/runbooks/console_boot_failed.md`
  - [ ] Создан `docs/runbooks/console_boot_failed.md` с разделами `Symptoms`, `Diagnosis`, `Resolution`
  - [ ] Обновлён `docs/ui/panel0.md`: fallback, hotkey, env, Core DOWN + Console DOWN
  - [ ] **Проверка (pass/fail):** `bash scripts/ci/check_panel0_stage16_docs.sh`.

## Документация (RU)
- [ ] docs/ui/panel0.md
- [ ] docs/ui/panel0_offline.md
- [ ] docs/ui/panel0_sw_cache.md
- [ ] docs/runbooks/console_boot_failed.md
- [ ] docs/governance/observability_gap_registry.md
- [ ] docs/ops/panel0_linux_prod_readiness.md

## Тестирование
- [ ] e2e: gap highlight (историческое покрытие panel0-e2e)
- [ ] e2e: core-down placeholder (историческое покрытие panel0-e2e + runtime markers)
- [ ] e2e: offline cache и negative SW сценарии (историческое покрытие panel0-e2e)
- [ ] e2e: EN default + RU switch (panel0-i18n-law-tests)
- [ ] e2e: auto-fallback при Console DOWN (5s timeout)
- [ ] e2e: observability_gap.console_boot_failed появляется в snapshot/stream
- [ ] e2e: hotkey Ctrl+Shift+P открывает Panel0
- [ ] e2e: Core DOWN + Console DOWN -> core-down placeholder
- [ ] linux prod-readiness: `bash scripts/tests/panel0_linux_prod_readiness.sh` (Console UP/HTTP error/timeout/hotkey/backlog/Core DOWN recovery)

## CI gate
- [ ] `panel0-e2e` запускает `node --test test/panel0.e2e.test.js`
- [ ] `stage16-docs-gate` запускает:
  - [ ] `bash scripts/ci/check_panel0_stage16_docs.sh`
  - [ ] `bash scripts/ci/check_panel0_stage16_runtime.sh`
- [ ] Runtime gate проверяет `/`, `/panel0/*`, event-контракт `console_boot_failed`, snapshot/stream.

## DoD
- [ ] Документация обновлена и непротиворечива (registry + runbook + panel0 docs).
- [ ] Core отдаёт embedded `/panel0/*` без зависимости от ФС.
- [ ] `GET /` реализует fallback Console -> Panel0 за 5 секунд.
- [ ] Событие `observability_gap.console_boot_failed` проходит в snapshot/stream с обязательным evidence.
- [ ] Горячая клавиша `Ctrl+Shift+P` открывает Panel0 и не создаёт искусственный `reason_type`.
- [ ] CI Stage16 (docs + runtime) проходит.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
