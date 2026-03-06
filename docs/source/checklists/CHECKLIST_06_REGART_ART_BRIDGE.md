A) Полный запрет опциональности:
# CHECKLIST 06 — REGART→Art Bridge readiness (обёртка)
Файл: CHECKLIST_06_REGART_ART_BRIDGE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменения в `CHECKLIST_REGART_ART_INTEGRATION.md`; изменения TLS/actions/overflow policies; изменения схем RawEvent/UiError/Audit
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

Внешний source-of-truth (REGART):
- Локально (если репозитории рядом): `../my_langgraph_agent/CHECKLIST_REGART_ART_INTEGRATION.md`
- GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`

## Цель
Закрыть готовность REGART к Art по источнику правды `CHECKLIST_REGART_ART_INTEGRATION.md` и обеспечить обязательные требования: overflow policies, управление только через Art Actions, TLS всегда, upstream error format, `retry_count`, audit immutability.

## Границы
Чек-лист является обёрткой и не дублирует `CHECKLIST_REGART_ART_INTEGRATION.md`. Все “реальные” пункты должны быть добавлены/закрыты в `CHECKLIST_REGART_ART_INTEGRATION.md` после фактической проверки.

## Зависимости
CHECKLIST 05 — REGART: UI/Graph/Run/Debugger (обёртка)

## Шаги (строго линейно)

- [x] **1. Сделать:** Внести в `CHECKLIST_REGART_ART_INTEGRATION.md` политику overflow для Outbox/Spool и реализовать её (см. новый test + `scripts/ci/check_stage06_wrapper.sh`).
  - [x] Политика по умолчанию: `never_drop_unacked`
    - [x] при заполнении: reject new (см. `test_never_drop_unacked_rejects_new` + `scripts/ci/check_stage06_wrapper.sh` вывод `observability_gap.spool_full`).
    - [x] генерируется `observability_gap.outbox_full` и/или `observability_gap.spool_full` (логируется `observability_gap.spool_full` + 507 `spool_full`).
  - [x] Альтернативный режим: `drop_oldest_when_full` (подтвержден `scripts/ci/check_stage06_wrapper.sh` + `test_drop_oldest_when_full_logs_lossy`)
    - [x] при заполнении: drop oldest
    - [x] генерируется `data_quality.lossy_outbox_drop` и/или `data_quality.lossy_spool_drop`
    - [x] создаётся инцидент `lossy_mode_active`
    - [x] увеличиваются метрики: `outbox_dropped_total` и/или `spool_dropped_total`
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены пункты про оба режима + тесты, log `lossy_mode_active`, `data_quality.lossy_*` зафиксирован.

- [x] **2. Сделать:** Внести требование и реализовать: управление сервисами выполняется только через Art Actions `POST /api/v1/actions/execute`. Evidence: `tests/integration_tests/test_ui_proxy_service_actions.py` + `scripts/ci/check_stage06_wrapper.sh`.
  - [x] прямые вызовы `systemctl`, `tmux`, shell-скриптов из UI Proxy запрещены (`rg "systemctl|tmux" agent/src/react_agent/ui_proxy.py` = 0).
  - [x] UI Proxy реализует только Art Actions API (`service_control`, `service_status`) и при сбоях логирует `observability_gap.actions.failure`.
  - [x] **Проверка (pass/fail):** `tests/integration_tests/test_ui_proxy_service_actions.py` + `scripts/ci/check_stage06_wrapper.sh`.

- [x] **3. Сделать:** Внести требование и реализовать: UI Proxy↔Art Core всегда HTTPS.
  - [x] для dev допускается self-signed сертификат (`ART_TLS_VERIFY=0`)
  - [x] HTTP запрещён (runtime блокирует non-https URL в `_ensure_art_tls_config`)
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` пункт “HTTPS-only” закрыт `[x]`; evidence: `test_art_ingest_https_only_rejects_http`, `test_art_ingest_tls_smoke_self_signed`.

- [x] **4. Сделать:** Внести требование и реализовать: upstream ошибки оформляются единым форматом и порождают RawEvent `kind="upstream_error"`.
  - [x] формат содержит поля: `what`, `where`, `why`, `actions`, `evidence`
  - [x] RawEvent `kind="upstream_error"` содержит `trace_id` и `retry_count`
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “upstream_error RawEvent format + test”, закрыт `[x]`; evidence: `test_upstream_error_format_contains_required_fields`.

- [x] **5. Сделать:** Внести требование и реализовать: RawEvent содержит `retry_count >= 0` (текущий хоп).
  - [x] `retry_count` присутствует всегда
  - [x] тип — целое число, минимум 0
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “retry_count contract + test”, закрыт `[x]`; evidence: `test_retry_count_present_and_non_negative`.

- [x] **6. Сделать:** Внести требование и реализовать: audit immutability test (append-only) обязателен.
  - [x] запрещена модификация записей аудита
  - [x] запрещено удаление записей аудита
  - [x] тест подтверждает append-only поведение (попытка update/delete → fail)
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “audit immutability test”, закрыт `[x]`; evidence: `test_audit_immutability_append_only`.

- [x] **7. Сделать:** RU-дока: overflow policies + TLS + actions путь.
  - [x] описан `never_drop_unacked` (поведение + события/метрики)
  - [x] описан `drop_oldest_when_full` (поведение + события/метрики + инцидент)
  - [x] описан “Actions-only” путь `POST /api/v1/actions/execute`
  - [x] описан “HTTPS-only” (dev self-signed)
  - [x] **Проверка (pass/fail):** `docs/regart/art_bridge_runbook.md` существует и содержит все пункты выше.

- [x] **8. Сделать:** RU-дока: upstream error format.
  - [x] формат `what/where/why/actions/evidence` описан явно
  - [x] пример RawEvent `kind="upstream_error"` с `trace_id` и `retry_count`
  - [x] **Проверка (pass/fail):** `docs/regart/upstream_error_format.md` существует и содержит все пункты выше.

## Документация (RU)
- [x] docs/regart/art_bridge_runbook.md
- [x] docs/regart/upstream_error_format.md

- ## Тестирование
- [x] integration: overflow политики Outbox/Spool в режиме `never_drop_unacked` (reject new + `observability_gap.*` + метрики)
- [x] integration: overflow политики Outbox/Spool в режиме `drop_oldest_when_full` (drop oldest + `data_quality.*` + инцидент `lossy_mode_active` + `*_dropped_total`)
- [x] integration: путь управления через Art Actions `POST /api/v1/actions/execute` (`tests/integration_tests/test_ui_proxy_service_actions.py`)
- [x] integration: HTTPS smoke UI Proxy↔Art Core (`test_art_ingest_https_only_rejects_http`, `test_art_ingest_tls_smoke_self_signed`)
- [x] integration: upstream error → RawEvent `kind="upstream_error"` с `what/where/why/actions/evidence/trace_id/retry_count` (`test_upstream_error_format_contains_required_fields`)
- [x] integration: audit immutability (append-only) тест зелёный (`test_audit_immutability_append_only`)

## CI gate
- [x] В CI workflow включён запуск тестов из раздела “Тестирование” через `scripts/ci/check_stage06_wrapper.sh` в двух режимах:
  - [x] default CI mode (`STAGE06_EXTERNAL_STRICT=0`) не зависит от внешнего репозитория и проверяет локальный wrapper + runbook/docs + непротиворечивость чек-листа
  - [x] strict mode (`STAGE06_EXTERNAL_STRICT=1`) использует локальный checkout `my_langgraph_agent` и выполняет кодовые проверки source-of-truth (`ui_proxy.py` + integration tests patterns + AST checks)
- [x] В CI workflow включён статический gate `scripts/ci/check_stage06_wrapper.sh`, который:
  - [x] проверяет, что в `CHECKLIST_REGART_ART_INTEGRATION.md` присутствуют пункты требований Шагов 1–6 (по стабильным строкам/паттернам)
  - [x] проверяет, что существуют `docs/regart/art_bridge_runbook.md` и `docs/regart/upstream_error_format.md`
  - [x] валидирует, что нет противоречий вида parent `[x]` + child `[ ]` в wrapper/source-of-truth чек-листах
  - [x] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [x] Все шаги 1–8 этого чек-листа отмечены `[x]` после фактической проверки.
- [x] Соответствующие пункты в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены и отмечены `[x]` с evidence.
- [x] Тесты из раздела “Тестирование” зелёные в CI.
- [x] CI gate из раздела “CI gate” зелёный в CI (`scripts/ci/check_stage06_wrapper.sh`).
- [x] `scripts/ci/check_stage06_wrapper.sh` проходил: `./scripts/ci/check_stage06_wrapper.sh` (7 passed).  
- [x] `agent/tests/integration_tests/test_ui_art_ingest.py::test_drop_oldest_when_full_logs_lossy` подтверждает `drop_oldest_when_full`, `lossy_mode_active` и `data_quality.lossy`.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
