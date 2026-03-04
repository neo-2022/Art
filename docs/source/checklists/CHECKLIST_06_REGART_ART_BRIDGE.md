A) Полный запрет опциональности:
# CHECKLIST 06 — REGART→Art Bridge readiness (обёртка)
Файл: CHECKLIST_06_REGART_ART_BRIDGE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменения в `CHECKLIST_REGART_ART_INTEGRATION.md`; изменения TLS/actions/overflow policies; изменения схем RawEvent/UiError/Audit

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

- [x] **1. Сделать:** Внести в `CHECKLIST_REGART_ART_INTEGRATION.md` политику overflow для Outbox/Spool и реализовать её.
  - [x] Политика по умолчанию: `never_drop_unacked`
    - [x] при заполнении: reject new
    - [x] генерируется `observability_gap.outbox_full` и/или `observability_gap.spool_full`
  - [x] Альтернативный режим: `drop_oldest_when_full`
    - [x] при заполнении: drop oldest
    - [x] генерируется `data_quality.lossy_outbox_drop` и/или `data_quality.lossy_spool_drop`
    - [x] создаётся инцидент `lossy_mode_active`
    - [x] увеличиваются метрики: `outbox_dropped_total` и/или `spool_dropped_total`
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены пункты про оба режима + тесты; эти пункты закрыты `[x]` с evidence (команды/логи/вывод тестов).

- [x] **2. Сделать:** Внести требование и реализовать: управление сервисами выполняется только через Art Actions `POST /api/v1/actions/execute`.
  - [x] прямые вызовы `systemd`, `tmux`, shell-скриптов из UI Proxy запрещены
  - [x] UI Proxy не содержит кода “управления системой” (только вызов Art Actions API)
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “Actions-only”, закрыт `[x]` с evidence (grep/код-ревью/тест).

- [x] **3. Сделать:** Внести требование и реализовать: UI Proxy↔Art Core всегда HTTPS.
  - [x] для dev допускается self-signed сертификат
  - [x] HTTP запрещён (не используется в транспортном контуре UI Proxy↔Art Core)
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “HTTPS-only”, закрыт `[x]` с evidence (smoke-тест/лог подключения).

- [x] **4. Сделать:** Внести требование и реализовать: upstream ошибки оформляются единым форматом и порождают RawEvent `kind="upstream_error"`.
  - [x] формат содержит поля: `what`, `where`, `why`, `actions`, `evidence`
  - [x] RawEvent `kind="upstream_error"` содержит `trace_id` и `retry_count`
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “upstream_error RawEvent format + test”, закрыт `[x]` с evidence.

- [x] **5. Сделать:** Внести требование и реализовать: RawEvent содержит `retry_count >= 0` (текущий хоп).
  - [x] `retry_count` присутствует всегда
  - [x] тип — целое число, минимум 0
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “retry_count contract + test”, закрыт `[x]` с evidence.

- [x] **6. Сделать:** Внести требование и реализовать: audit immutability test (append-only) обязателен.
  - [x] запрещена модификация записей аудита
  - [x] запрещено удаление записей аудита
  - [x] тест подтверждает append-only поведение (попытка update/delete → fail)
  - [x] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “audit immutability test”, закрыт `[x]` с evidence.

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

## Тестирование
- [x] integration: overflow политики Outbox/Spool в режиме `never_drop_unacked` (reject new + `observability_gap.*` + метрики)
- [x] integration: overflow политики Outbox/Spool в режиме `drop_oldest_when_full` (drop oldest + `data_quality.*` + инцидент `lossy_mode_active` + `*_dropped_total`)
- [x] integration: путь управления через Art Actions `POST /api/v1/actions/execute`
- [x] integration: HTTPS smoke UI Proxy↔Art Core
- [x] integration: upstream error → RawEvent `kind="upstream_error"` с `what/where/why/actions/evidence/trace_id/retry_count`
- [x] integration: audit immutability (append-only) тест зелёный

## CI gate
- [x] В CI workflow включён запуск тестов из раздела “Тестирование”.
- [x] В CI workflow включён статический gate `scripts/ci/check_stage06_wrapper.sh`, который:
  - [x] проверяет, что в `CHECKLIST_REGART_ART_INTEGRATION.md` присутствуют пункты требований Шагов 1–6 (по стабильным строкам/паттернам)
  - [x] проверяет, что существуют `docs/regart/art_bridge_runbook.md` и `docs/regart/upstream_error_format.md`
  - [x] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [x] Все шаги 1–8 этого чек-листа отмечены `[x]` после фактической проверки.
- [x] Соответствующие пункты в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены и отмечены `[x]` с evidence.
- [x] Тесты из раздела “Тестирование” зелёные в CI.
- [x] CI gate из раздела “CI gate” зелёный в CI.
