A) Полный запрет опциональности:
# CHECKLIST 10 — Art Browser Level0 (универсальный)
Файл: CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
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

- [x] **1. Сделать:** Реализовать multi-tab дедуп отправки (leader tab отправляет; обе вкладки видят локально).
  - [x] Вкладка генерирует `tab_id` (UUIDv4) и хранит в `sessionStorage` (только текущая вкладка)
  - [x] Лидер определяется через `localStorage`-lock `art:l0:leader` с heartbeat:
    - [x] лидер пишет `{"tab_id":"...","ts_ms":...}` каждые 1000 мс
    - [x] лидерство считается потерянным, если `ts_ms` старше 3000 мс
    - [x] при потере лидерства другая вкладка захватывает lock и становится лидером
  - [x] Только лидер выполняет flush в сеть (в Art ingest)
  - [x] Все вкладки публикуют локальные события в `BroadcastChannel` `art:l0:events` и отображают/учитывают их локально
  - [x] Dedup-ключ фиксирован:
    - [x] `dedup_key = sha256(canonical_json(normalized_event))`
    - [x] `canonical_json` — JSON с отсортированными ключами и без полей `ts_ms`
    - [x] TTL дедуп-таблицы: 300000 мс
  - [x] **Проверка (pass/fail):** e2e multi-tab тест зелёный: 2 вкладки → локально видно в обеих → в Art доставлено ровно 1 раз (по `dedup_key`).

- [x] **2. Сделать:** Реализовать CORS blocked → `observability_gap.cors_blocked`.
  - [x] При любой CORS-блокировке сеть/ingest фиксируется событие `observability_gap.cors_blocked` и оно попадает в snapshot/stream
  - [x] Событие содержит `what/where/why/evidence/actions` и `trace_id`
  - [x] evidence_min включает:
    - [x] endpoint
    - [x] browser origin
    - [x] тип блокировки (строка)
    - [x] retry_count (целое >= 0)
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/cors_blocked.md`
  - [x] **Проверка (pass/fail):** integration/e2e тест форсит CORS blocked и проверяет наличие события в snapshot/stream.

- [x] **3. Сделать:** Реализовать gzip compression при `payload_size_bytes > 1024` перед записью в IndexedDB.
  - [x] Порог сжатия фиксирован: 1024 байта
  - [x] Для записей outbox сохраняется метадата:
    - [x] `content_encoding` (значение `identity` или `gzip`)
    - [x] `original_size_bytes`
    - [x] `stored_size_bytes`
  - [x] При flush в сеть выполняется корректная распаковка и отправка оригинального payload
  - [x] При ошибке распаковки генерируется `observability_gap.outbox_decompress_failed` (snapshot/stream) с `trace_id` и evidence_min
  - [x] `observability_gap.outbox_decompress_failed` зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/outbox_decompress_failed.md`
  - [x] **Проверка (pass/fail):**
    - [x] unit тест compress/decompress зелёный
    - [x] integration тест: записывает payload>1024, flush доставляет валидный RawEvent и подтверждает корректность данных.

- [x] **4. Сделать:** Реализовать outbox TTL: `max_age=7 суток`; истёк → перенос в DLQ + `observability_gap.outbox_event_expired`.
  - [x] TTL фиксирован: 7 суток (604800000 мс)
  - [x] Истечение TTL приводит к:
    - [x] перемещению записи в DLQ
    - [x] генерации `observability_gap.outbox_event_expired` (snapshot/stream)
    - [x] увеличению счётчика `outbox_expired_total`
  - [x] DLQ retention фиксирован: 30 суток (2592000000 мс); истёк → hard delete + счётчик `dlq_purged_total`
  - [x] `observability_gap.outbox_event_expired` содержит evidence_min:
    - [x] dedup_key
    - [x] возраст (age_ms)
    - [x] policy=ttl_7d
    - [x] trace_id
  - [x] `observability_gap.outbox_event_expired` зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/outbox_event_expired.md`
  - [x] **Проверка (pass/fail):**
    - [x] unit тест TTL→DLQ зелёный
    - [x] integration тест: имитирует возраст >7 суток и проверяет перенос в DLQ + событие + метрику.

- [x] **5. Сделать:** Реализовать cleanup: при старте и каждые 5 минут.
  - [x] Cleanup запускается при старте приложения
  - [x] Cleanup запускается по таймеру каждые 300000 мс
  - [x] Cleanup выполняет:
    - [x] перенос истёкших outbox записей в DLQ (шаг 4)
    - [x] purge DLQ по DLQ retention (шаг 4)
    - [x] prune дедуп-таблицы по TTL (шаг 1)
  - [x] **Проверка (pass/fail):** unit тест таймера (симуляция времени) зелёный и подтверждает период 5 минут.

- [x] **6. Сделать:** Реализовать Web Worker как обязательный путь flush/сжатие/TTL; при невозможности Worker → fallback main-thread + `observability_gap.worker_unavailable`.
  - [x] По умолчанию используются Worker-операции для:
    - [x] flush
    - [x] gzip compress/decompress
    - [x] cleanup/TTL/DLQ
  - [x] При невозможности поднять Worker включается fallback main-thread:
    - [x] функциональность сохранена (flush/TTL/compress продолжают работать)
    - [x] генерируется `observability_gap.worker_unavailable` (snapshot/stream)
  - [x] `observability_gap.worker_unavailable` содержит evidence_min:
    - [x] причина (строка)
    - [x] browser details (строка)
    - [x] trace_id
  - [x] Событие зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev3`
    - [x] `action_ref=docs/runbooks/worker_unavailable.md`
  - [x] **Проверка (pass/fail):** integration тест принудительно отключает Worker и подтверждает:
    - [x] fallback включился
    - [x] flush/TTL/compress продолжают работать
    - [x] событие `observability_gap.worker_unavailable` видно в snapshot/stream.

- [x] **7. Сделать:** Реализовать overflow политики outbox и связанные события/метрики/инцидент `lossy_mode_active`.
  - [x] Политика по умолчанию: `never_drop_unacked`
    - [x] при заполнении outbox: reject new
    - [x] генерируется `observability_gap.outbox_full` (snapshot/stream)
    - [x] увеличивается `outbox_rejected_total`
    - [x] событие зарегистрировано в реестре с:
      - [x] `incident_rule=create_incident_min_sev1`
      - [x] `action_ref=docs/runbooks/outbox_full.md`
  - [x] Альтернативная политика: `drop_oldest_when_full`
    - [x] при заполнении outbox: drop oldest
    - [x] генерируется `data_quality.lossy_outbox_drop` (snapshot/stream)
    - [x] увеличивается `outbox_dropped_total`
    - [x] создаётся инцидент `lossy_mode_active` (как Incident/RawEvent по контракту Art)
    - [x] инцидент имеет severity не ниже SEV1
    - [x] `lossy_mode_active` ссылается на `action_ref=docs/runbooks/lossy_mode_active.md`
  - [x] **Проверка (pass/fail):** integration тесты для обеих политик зелёные и подтверждают события/метрики/инцидент.

## Документация (RU)
- [x] docs/browser/level0_api.md
- [x] docs/browser/outbox_limits.md
- [x] docs/browser/cors_gap.md
- [x] docs/browser/compression.md
- [x] docs/browser/dlq.md
- [x] docs/runbooks/cors_blocked.md
- [x] docs/runbooks/outbox_decompress_failed.md
- [x] docs/runbooks/outbox_event_expired.md
- [x] docs/runbooks/worker_unavailable.md
- [x] docs/runbooks/outbox_full.md
- [x] docs/runbooks/lossy_mode_active.md

## Тестирование
- [x] unit: outbox (insert/read/ack), dedup (TTL/prune), gzip (compress/decompress), TTL→DLQ, DLQ purge, cleanup timer
- [x] integration/e2e: multi-tab лидерство + “2 вкладки → 1 доставка”
- [x] integration/e2e: CORS blocked → `observability_gap.cors_blocked`
- [x] integration: payload>1024 → gzip хранение + корректная доставка
- [x] integration: Worker unavailable → fallback + `observability_gap.worker_unavailable`
- [x] integration: overflow политики outbox (never_drop_unacked / drop_oldest_when_full) + события/метрики/инцидент

## CI gate
- [x] browser lint/test/build зелёные
- [x] e2e smoke зелёный (multi-tab + cors blocked + worker fallback)
- [x] CI job `stage10-docs-gate` существует и запускается на PR в main
- [x] `stage10-docs-gate` запускает `scripts/ci/check_browser_level0_stage10_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/browser/compression.md` содержит `1024` и `gzip`
    - [x] `docs/browser/dlq.md` содержит `7 суток` и `30 суток`
    - [x] `docs/browser/cors_gap.md` содержит `observability_gap.cors_blocked`
    - [x] `docs/browser/outbox_limits.md` содержит `never_drop_unacked` и `drop_oldest_when_full`
    - [x] runbooks содержат `mitigations` и `verification`
  - [x] завершает работу с exit 1 при нарушении любой проверки

## DoD
- [x] Level0 полностью однозначен: multi-tab, worker/fallback, gzip>1024, TTL→DLQ, cleanup schedule, overflow политики.
- [x] Все события `observability_gap.*` зарегистрированы в реестре и имеют `action_ref` на конкретные runbook.
- [x] Тесты (unit+integration/e2e) зелёные.
- [x] CI gate Stage 10 зелёный.

