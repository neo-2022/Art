A) Полный запрет опциональности:
# CHECKLIST 10 — Art Browser Level0 (универсальный)
Файл: CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение backpressure/ack; изменение browser storage policy; изменение DLQ/TTL; изменение политики multi-tab; изменение политики worker/fallback

## Цель
Сделать Level0 без двусмысленности: multi-tab дедуп отправки, CORS gap, gzip>1024B, TTL=7 суток→DLQ, cleanup schedule, Worker обязателен + fallback gap, overflow политики outbox (never_drop_unacked / drop_oldest_when_full) и lossy_mode_active.

## Границы
Универсальный модуль Art (Browser Level0), без REGART-специфики.

## Зависимости
CHECKLIST 02 — Privacy baseline (global)  
CHECKLIST 03 — Regional profiles  
CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry  
CHECKLIST 09 — Telemetry alignment (OTel/OTLP)

## Шаги (строго линейно)

- [ ] **1. Сделать:** Реализовать multi-tab дедуп отправки (leader tab отправляет; обе вкладки видят локально).
  - [ ] Вкладка генерирует `tab_id` (UUIDv4) и хранит в `sessionStorage` (только текущая вкладка)
  - [ ] Лидер определяется через `localStorage`-lock `art:l0:leader` с heartbeat:
    - [ ] лидер пишет `{"tab_id":"...","ts_ms":...}` каждые 1000 мс
    - [ ] лидерство считается потерянным, если `ts_ms` старше 3000 мс
    - [ ] при потере лидерства другая вкладка захватывает lock и становится лидером
  - [ ] Только лидер выполняет flush в сеть (в Art ingest)
  - [ ] Все вкладки публикуют локальные события в `BroadcastChannel` `art:l0:events` и отображают/учитывают их локально
  - [ ] Dedup-ключ фиксирован:
    - [ ] `dedup_key = sha256(canonical_json(normalized_event))`
    - [ ] `canonical_json` — JSON с отсортированными ключами и без полей `ts_ms`
    - [ ] TTL дедуп-таблицы: 300000 мс
  - [ ] **Проверка (pass/fail):** e2e multi-tab тест зелёный: 2 вкладки → локально видно в обеих → в Art доставлено ровно 1 раз (по `dedup_key`).

- [ ] **2. Сделать:** Реализовать CORS blocked → `observability_gap.cors_blocked`.
  - [ ] При любой CORS-блокировке сеть/ingest фиксируется событие `observability_gap.cors_blocked` и оно попадает в snapshot/stream
  - [ ] Событие содержит `what/where/why/evidence/actions` и `trace_id`
  - [ ] evidence_min включает:
    - [ ] endpoint
    - [ ] browser origin
    - [ ] тип блокировки (строка)
    - [ ] retry_count (целое >= 0)
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/cors_blocked.md`
  - [ ] **Проверка (pass/fail):** integration/e2e тест форсит CORS blocked и проверяет наличие события в snapshot/stream.

- [ ] **3. Сделать:** Реализовать gzip compression при `payload_size_bytes > 1024` перед записью в IndexedDB.
  - [ ] Порог сжатия фиксирован: 1024 байта
  - [ ] Для записей outbox сохраняется метадата:
    - [ ] `content_encoding` (значение `identity` или `gzip`)
    - [ ] `original_size_bytes`
    - [ ] `stored_size_bytes`
  - [ ] При flush в сеть выполняется корректная распаковка и отправка оригинального payload
  - [ ] При ошибке распаковки генерируется `observability_gap.outbox_decompress_failed` (snapshot/stream) с `trace_id` и evidence_min
  - [ ] `observability_gap.outbox_decompress_failed` зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/outbox_decompress_failed.md`
  - [ ] **Проверка (pass/fail):**
    - [ ] unit тест compress/decompress зелёный
    - [ ] integration тест: записывает payload>1024, flush доставляет валидный RawEvent и подтверждает корректность данных.

- [ ] **4. Сделать:** Реализовать outbox TTL: `max_age=7 суток`; истёк → перенос в DLQ + `observability_gap.outbox_event_expired`.
  - [ ] TTL фиксирован: 7 суток (604800000 мс)
  - [ ] Истечение TTL приводит к:
    - [ ] перемещению записи в DLQ
    - [ ] генерации `observability_gap.outbox_event_expired` (snapshot/stream)
    - [ ] увеличению счётчика `outbox_expired_total`
  - [ ] DLQ retention фиксирован: 30 суток (2592000000 мс); истёк → hard delete + счётчик `dlq_purged_total`
  - [ ] `observability_gap.outbox_event_expired` содержит evidence_min:
    - [ ] dedup_key
    - [ ] возраст (age_ms)
    - [ ] policy=ttl_7d
    - [ ] trace_id
  - [ ] `observability_gap.outbox_event_expired` зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/outbox_event_expired.md`
  - [ ] **Проверка (pass/fail):**
    - [ ] unit тест TTL→DLQ зелёный
    - [ ] integration тест: имитирует возраст >7 суток и проверяет перенос в DLQ + событие + метрику.

- [ ] **5. Сделать:** Реализовать cleanup: при старте и каждые 5 минут.
  - [ ] Cleanup запускается при старте приложения
  - [ ] Cleanup запускается по таймеру каждые 300000 мс
  - [ ] Cleanup выполняет:
    - [ ] перенос истёкших outbox записей в DLQ (шаг 4)
    - [ ] purge DLQ по DLQ retention (шаг 4)
    - [ ] prune дедуп-таблицы по TTL (шаг 1)
  - [ ] **Проверка (pass/fail):** unit тест таймера (симуляция времени) зелёный и подтверждает период 5 минут.

- [ ] **6. Сделать:** Реализовать Web Worker как обязательный путь flush/сжатие/TTL; при невозможности Worker → fallback main-thread + `observability_gap.worker_unavailable`.
  - [ ] По умолчанию используются Worker-операции для:
    - [ ] flush
    - [ ] gzip compress/decompress
    - [ ] cleanup/TTL/DLQ
  - [ ] При невозможности поднять Worker включается fallback main-thread:
    - [ ] функциональность сохранена (flush/TTL/compress продолжают работать)
    - [ ] генерируется `observability_gap.worker_unavailable` (snapshot/stream)
  - [ ] `observability_gap.worker_unavailable` содержит evidence_min:
    - [ ] причина (строка)
    - [ ] browser details (строка)
    - [ ] trace_id
  - [ ] Событие зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev3`
    - [ ] `action_ref=docs/runbooks/worker_unavailable.md`
  - [ ] **Проверка (pass/fail):** integration тест принудительно отключает Worker и подтверждает:
    - [ ] fallback включился
    - [ ] flush/TTL/compress продолжают работать
    - [ ] событие `observability_gap.worker_unavailable` видно в snapshot/stream.

- [ ] **7. Сделать:** Реализовать overflow политики outbox и связанные события/метрики/инцидент `lossy_mode_active`.
  - [ ] Политика по умолчанию: `never_drop_unacked`
    - [ ] при заполнении outbox: reject new
    - [ ] генерируется `observability_gap.outbox_full` (snapshot/stream)
    - [ ] увеличивается `outbox_rejected_total`
    - [ ] событие зарегистрировано в реестре с:
      - [ ] `incident_rule=create_incident_min_sev1`
      - [ ] `action_ref=docs/runbooks/outbox_full.md`
  - [ ] Альтернативная политика: `drop_oldest_when_full`
    - [ ] при заполнении outbox: drop oldest
    - [ ] генерируется `data_quality.lossy_outbox_drop` (snapshot/stream)
    - [ ] увеличивается `outbox_dropped_total`
    - [ ] создаётся инцидент `lossy_mode_active` (как Incident/RawEvent по контракту Art)
    - [ ] инцидент имеет severity не ниже SEV1
    - [ ] `lossy_mode_active` ссылается на `action_ref=docs/runbooks/lossy_mode_active.md`
  - [ ] **Проверка (pass/fail):** integration тесты для обеих политик зелёные и подтверждают события/метрики/инцидент.

## Документация (RU)
- [ ] docs/browser/level0_api.md
- [ ] docs/browser/outbox_limits.md
- [ ] docs/browser/cors_gap.md
- [ ] docs/browser/compression.md
- [ ] docs/browser/dlq.md
- [ ] docs/runbooks/cors_blocked.md
- [ ] docs/runbooks/outbox_decompress_failed.md
- [ ] docs/runbooks/outbox_event_expired.md
- [ ] docs/runbooks/worker_unavailable.md
- [ ] docs/runbooks/outbox_full.md
- [ ] docs/runbooks/lossy_mode_active.md

## Тестирование
- [ ] unit: outbox (insert/read/ack), dedup (TTL/prune), gzip (compress/decompress), TTL→DLQ, DLQ purge, cleanup timer
- [ ] integration/e2e: multi-tab лидерство + “2 вкладки → 1 доставка”
- [ ] integration/e2e: CORS blocked → `observability_gap.cors_blocked`
- [ ] integration: payload>1024 → gzip хранение + корректная доставка
- [ ] integration: Worker unavailable → fallback + `observability_gap.worker_unavailable`
- [ ] integration: overflow политики outbox (never_drop_unacked / drop_oldest_when_full) + события/метрики/инцидент

## CI gate
- [ ] browser lint/test/build зелёные
- [ ] e2e smoke зелёный (multi-tab + cors blocked + worker fallback)
- [ ] CI job `stage10-docs-gate` существует и запускается на PR в main
- [ ] `stage10-docs-gate` запускает `scripts/ci/check_browser_level0_stage10_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/browser/compression.md` содержит `1024` и `gzip`
    - [ ] `docs/browser/dlq.md` содержит `7 суток` и `30 суток`
    - [ ] `docs/browser/cors_gap.md` содержит `observability_gap.cors_blocked`
    - [ ] `docs/browser/outbox_limits.md` содержит `never_drop_unacked` и `drop_oldest_when_full`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [ ] Level0 полностью однозначен: multi-tab, worker/fallback, gzip>1024, TTL→DLQ, cleanup schedule, overflow политики.
- [ ] Все события `observability_gap.*` зарегистрированы в реестре и имеют `action_ref` на конкретные runbook.
- [ ] Тесты (unit+integration/e2e) зелёные.
- [ ] CI gate Stage 10 зелёный.

