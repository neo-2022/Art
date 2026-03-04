A) Полный запрет опциональности:
# CHECKLIST 06 — REGART→Art Bridge readiness (обёртка)
Файл: CHECKLIST_06_REGART_ART_BRIDGE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
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

- [ ] **1. Сделать:** Внести в `CHECKLIST_REGART_ART_INTEGRATION.md` политику overflow для Outbox/Spool и реализовать её.
  - [ ] Политика по умолчанию: `never_drop_unacked`
    - [ ] при заполнении: reject new
    - [ ] генерируется `observability_gap.outbox_full` и/или `observability_gap.spool_full`
  - [ ] Альтернативный режим: `drop_oldest_when_full`
    - [ ] при заполнении: drop oldest
    - [ ] генерируется `data_quality.lossy_outbox_drop` и/или `data_quality.lossy_spool_drop`
    - [ ] создаётся инцидент `lossy_mode_active`
    - [ ] увеличиваются метрики: `outbox_dropped_total` и/или `spool_dropped_total`
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены пункты про оба режима + тесты; эти пункты закрыты `[x]` с evidence (команды/логи/вывод тестов).

- [ ] **2. Сделать:** Внести требование и реализовать: управление сервисами выполняется только через Art Actions `POST /api/v1/actions/execute`.
  - [ ] прямые вызовы `systemd`, `tmux`, shell-скриптов из UI Proxy запрещены
  - [ ] UI Proxy не содержит кода “управления системой” (только вызов Art Actions API)
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “Actions-only”, закрыт `[x]` с evidence (grep/код-ревью/тест).

- [ ] **3. Сделать:** Внести требование и реализовать: UI Proxy↔Art Core всегда HTTPS.
  - [ ] для dev допускается self-signed сертификат
  - [ ] HTTP запрещён (не используется в транспортном контуре UI Proxy↔Art Core)
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “HTTPS-only”, закрыт `[x]` с evidence (smoke-тест/лог подключения).

- [ ] **4. Сделать:** Внести требование и реализовать: upstream ошибки оформляются единым форматом и порождают RawEvent `kind="upstream_error"`.
  - [ ] формат содержит поля: `what`, `where`, `why`, `actions`, `evidence`
  - [ ] RawEvent `kind="upstream_error"` содержит `trace_id` и `retry_count`
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “upstream_error RawEvent format + test”, закрыт `[x]` с evidence.

- [ ] **5. Сделать:** Внести требование и реализовать: RawEvent содержит `retry_count >= 0` (текущий хоп).
  - [ ] `retry_count` присутствует всегда
  - [ ] тип — целое число, минимум 0
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “retry_count contract + test”, закрыт `[x]` с evidence.

- [ ] **6. Сделать:** Внести требование и реализовать: audit immutability test (append-only) обязателен.
  - [ ] запрещена модификация записей аудита
  - [ ] запрещено удаление записей аудита
  - [ ] тест подтверждает append-only поведение (попытка update/delete → fail)
  - [ ] **Проверка (pass/fail):** в `CHECKLIST_REGART_ART_INTEGRATION.md` есть пункт “audit immutability test”, закрыт `[x]` с evidence.

- [ ] **7. Сделать:** RU-дока: overflow policies + TLS + actions путь.
  - [ ] описан `never_drop_unacked` (поведение + события/метрики)
  - [ ] описан `drop_oldest_when_full` (поведение + события/метрики + инцидент)
  - [ ] описан “Actions-only” путь `POST /api/v1/actions/execute`
  - [ ] описан “HTTPS-only” (dev self-signed)
  - [ ] **Проверка (pass/fail):** `docs/regart/art_bridge_runbook.md` существует и содержит все пункты выше.

- [ ] **8. Сделать:** RU-дока: upstream error format.
  - [ ] формат `what/where/why/actions/evidence` описан явно
  - [ ] пример RawEvent `kind="upstream_error"` с `trace_id` и `retry_count`
  - [ ] **Проверка (pass/fail):** `docs/regart/upstream_error_format.md` существует и содержит все пункты выше.

## Документация (RU)
- [ ] docs/regart/art_bridge_runbook.md
- [ ] docs/regart/upstream_error_format.md

## Тестирование
- [ ] integration: overflow политики Outbox/Spool в режиме `never_drop_unacked` (reject new + `observability_gap.*` + метрики)
- [ ] integration: overflow политики Outbox/Spool в режиме `drop_oldest_when_full` (drop oldest + `data_quality.*` + инцидент `lossy_mode_active` + `*_dropped_total`)
- [ ] integration: путь управления через Art Actions `POST /api/v1/actions/execute`
- [ ] integration: HTTPS smoke UI Proxy↔Art Core
- [ ] integration: upstream error → RawEvent `kind="upstream_error"` с `what/where/why/actions/evidence/trace_id/retry_count`
- [ ] integration: audit immutability (append-only) тест зелёный

## CI gate
- [ ] В CI workflow включён запуск тестов из раздела “Тестирование”.
- [ ] В CI workflow включён статический gate `scripts/ci/check_stage06_wrapper.sh`, который:
  - [ ] проверяет, что в `CHECKLIST_REGART_ART_INTEGRATION.md` присутствуют пункты требований Шагов 1–6 (по стабильным строкам/паттернам)
  - [ ] проверяет, что существуют `docs/regart/art_bridge_runbook.md` и `docs/regart/upstream_error_format.md`
  - [ ] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [ ] Все шаги 1–8 этого чек-листа отмечены `[x]` после фактической проверки.
- [ ] Соответствующие пункты в `CHECKLIST_REGART_ART_INTEGRATION.md` добавлены и отмечены `[x]` с evidence.
- [ ] Тесты из раздела “Тестирование” зелёные в CI.
- [ ] CI gate из раздела “CI gate” зелёный в CI.
