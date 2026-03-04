A) Полный запрет опциональности:
# CHECKLIST 18 — Art Agent Receivers v1
Файл: CHECKLIST_18_ART_AGENT_RECEIVERS.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (перепроверка, reopened)  
Триггер пересмотра: изменение формата RawEvent; изменение redaction rules; изменение spool/outbox политики; добавление/изменение receiver kinds; изменение политики multiline/парсинга

## Цель
Receivers в агенте однозначны и проверяемы: фиксированный список receiver kinds v1, детерминированный контракт `source_id/source_seq`, корректный парсинг (включая multiline), pre-write redaction, backpressure от spool/outbox, и обязательные `observability_gap.*`/`data_quality.*` события с runbook.

## Границы
Только слой Receivers в Art Agent: чтение источников, нормализация в RawEvent, привязка `source_id/source_seq`, отправка в spool/outbox.  
Core ingest/storage/pipeline — в других чек-листах.

## Зависимости
- CHECKLIST 17 — Art Agent Spool/Outbox
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, runbooks)

## Статус перепроверки
- Закрытие этапа снято: артефакты и docs добавлены, но реализация по коду/интеграционным тестам/chaos не подтверждена полностью.
- До полного соответствия все пункты этапа считаются незакрытыми.

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать receiver API/контракт и список receiver kinds v1 (ровно фиксированный набор).
  - [ ] `receiver_kind` (enum) фиксирован и содержит ровно:
    - [ ] `file_tail`
    - [ ] `journald`
    - [ ] `stdout_stderr` (обёртка запуска процесса/pipe)
  - [ ] Каждый receiver генерирует RawEvent со строгими полями:
    - [ ] `source_id` (строка, уникальна в рамках агента)
    - [ ] `source_seq` (целое >= 0, монотонно растёт для данного source_id)
    - [ ] `source_ts_ms` (целое >= 0)
    - [ ] `receiver_kind` (одно из enum)
    - [ ] `trace_id` (всегда; генерируется при отсутствии)
    - [ ] `retry_count` (всегда; целое >= 0)
  - [ ] Правило уникальности `source_id` фиксировано:
    - [ ] `file_tail`: `file:<abs_path>`
    - [ ] `journald`: `journald:<unit_or_matcher_id>`
    - [ ] `stdout_stderr`: `proc:<command_id>`
  - [ ] **Проверка (pass/fail):** существует `docs/agent/receivers.md`, содержит enum, контракт полей и правила source_id.

- [ ] **2. Сделать:** Реализовать pre-write redaction в receivers ДО записи в spool/outbox.
  - [ ] redaction применяется к:
    - [ ] `message`
    - [ ] `payload` (включая structured fields)
    - [ ] `ctx` (если заполняется)
    - [ ] метаданным receiver (например file path в message запрещён; допускается только в `source_id`)
  - [ ] redaction использует конфиг rules Stage 02
  - [ ] при фактической правке данных генерируется `privacy.redaction_applied` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** security test подаёт секрет/PII на вход receiver и проверяет:
    - [ ] в spool/outbox нет исходного секрета
    - [ ] есть маска/удаление
    - [ ] `privacy.redaction_applied` сработал.

- [ ] **3. Сделать:** Реализовать parsing policy: plain + structured + multiline (фиксированное поведение).
  - [ ] Базовый режим: line-based (каждая строка → 1 RawEvent)
  - [ ] Structured режим (JSON line):
    - [ ] если строка валидный JSON object → кладётся в `payload.structured` (объект)
    - [ ] исходная строка сохраняется как `payload.raw_line` (строка)
  - [ ] Multiline режим фиксирован:
    - [ ] начало события: regex `^(\S+\s+\S+|{)` (одно фиксированное правило)
    - [ ] продолжение: строки до следующего “начала”
    - [ ] max_lines_per_event=50
    - [ ] max_event_bytes=65536
  - [ ] при превышении лимитов multiline генерируется `data_quality.receiver_multiline_truncated` (snapshot/stream)
  - [ ] при ошибке парсинга structured JSON генерируется `data_quality.receiver_parse_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** unit tests покрывают:
    - [ ] plain lines
    - [ ] structured JSON line success
    - [ ] structured JSON parse fail → событие `data_quality.receiver_parse_failed`
    - [ ] multiline сборка
    - [ ] multiline truncation → событие `data_quality.receiver_multiline_truncated`.

- [ ] **4. Сделать:** Реализовать backpressure receivers от spool/outbox (строгое поведение).
  - [ ] Default: при `spool_overflow_policy=never_drop_unacked`:
    - [ ] receiver прекращает чтение источника (pause)
    - [ ] генерируется `observability_gap.receiver_paused_spool_full` (snapshot/stream)
  - [ ] При `spool_overflow_policy=drop_oldest_when_full`:
    - [ ] receiver продолжает чтение
    - [ ] потери фиксируются событиями lossy из Stage 17 (spool drop) + локально `data_quality.receiver_lossy_mode_active` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] форсит spool full в `never_drop_unacked` и проверяет pause + `observability_gap.receiver_paused_spool_full`
    - [ ] форсит spool full в `drop_oldest_when_full` и проверяет продолжение чтения + lossy события.

- [ ] **5. Сделать:** Реализовать receiver `file_tail` (log rotation + offset persistence).
  - [ ] читает файл по абсолютному пути
  - [ ] хранит offset в state-файле (фиксированный путь и формат описаны)
  - [ ] обрабатывает log rotation:
    - [ ] inode change → продолжает с 0 нового файла
    - [ ] старый inode дочитывается до EOF, затем переключение (одно фиксированное поведение)
  - [ ] permission denied → `observability_gap.receiver_permission_denied` (snapshot/stream)
  - [ ] read error → `observability_gap.receiver_read_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration tests:
    - [ ] tail читает строки и source_seq монотонен
    - [ ] rotation сценарий проходит и не теряет порядок source_seq
    - [ ] permission denied вызывает `observability_gap.receiver_permission_denied`.

- [ ] **6. Сделать:** Реализовать receiver `journald` (cursor persistence).
  - [ ] фильтр фиксирован: `UNIT=<service>` (одно фиксированное решение)
  - [ ] хранит journald cursor в state-файле
  - [ ] перезапуск агента продолжает чтение с сохранённого cursor
  - [ ] read error → `observability_gap.receiver_read_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] читает записи из journald
    - [ ] после рестарта продолжает с cursor (не дублирует и не пропускает)
    - [ ] source_seq монотонен.

- [ ] **7. Сделать:** Реализовать receiver `stdout_stderr` (wrapper).
  - [ ] запускает процесс по фиксированному `command_id`
  - [ ] читает stdout и stderr как два канала:
    - [ ] `payload.stream="stdout"` / `payload.stream="stderr"`
  - [ ] exit non-zero → `observability_gap.receiver_process_exited` (snapshot/stream)
  - [ ] spawn error → `observability_gap.receiver_process_spawn_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] stdout/stderr события приходят
    - [ ] non-zero exit порождает `observability_gap.receiver_process_exited`.

- [ ] **8. Сделать:** Зарегистрировать все receiver gap/quality события в реестре `observability_gap_registry.md` и зафиксировать incident_rule + runbook.
  - [ ] `observability_gap.receiver_paused_spool_full`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_paused_spool_full.md`
  - [ ] `observability_gap.receiver_permission_denied`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_permission_denied.md`
  - [ ] `observability_gap.receiver_read_failed`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_read_failed.md`
  - [ ] `observability_gap.receiver_process_spawn_failed`:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/receiver_process_spawn_failed.md`
  - [ ] `observability_gap.receiver_process_exited`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_process_exited.md`
  - [ ] **Проверка (pass/fail):** реестр содержит все события выше с `incident_rule` и `action_ref`; все runbook файлы существуют.

- [ ] **9. Сделать:** RU-дока receivers: конфиг, state, примеры, ограничения.
  - [ ] `docs/agent/receivers.md` содержит контракт (шаг 1)
  - [ ] `docs/agent/receivers_config.md` содержит фиксированный формат конфига receivers и:
    - [ ] пример для file_tail
    - [ ] пример для journald
    - [ ] пример для stdout_stderr
  - [ ] `docs/agent/receivers_state.md` описывает state файлы (offset/cursor) и их формат
  - [ ] **Проверка (pass/fail):** документы существуют и содержат указанные примеры и поля.

## Документация (RU)
- [ ] docs/agent/receivers.md
- [ ] docs/agent/receivers_config.md
- [ ] docs/agent/receivers_state.md
- [ ] docs/runbooks/receiver_paused_spool_full.md
- [ ] docs/runbooks/receiver_permission_denied.md
- [ ] docs/runbooks/receiver_read_failed.md
- [ ] docs/runbooks/receiver_process_spawn_failed.md
- [ ] docs/runbooks/receiver_process_exited.md

## Тестирование
- [ ] unit: parsing (plain/structured/multiline) + truncation + parse_failed
- [ ] security: pre-write redaction + `privacy.redaction_applied`
- [ ] integration: file_tail (offset + rotation + permission denied)
- [ ] integration: journald (cursor persistence)
- [ ] integration: stdout_stderr (spawn + exit non-zero)
- [ ] integration: backpressure pause/continue по политикам spool (Stage 17)

## CI gate
- [ ] CI job `agent-receivers-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage18-docs-gate` существует и запускается на PR в main
- [ ] `stage18-docs-gate` запускает `scripts/ci/check_agent_receivers_stage18_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/agent/receivers.md` содержит `receiver_kind` и `source_id` и `source_seq`
    - [ ] `docs/agent/receivers_config.md` содержит `file_tail` и `journald` и `stdout_stderr`
    - [ ] `docs/agent/receivers_state.md` содержит `offset` и `cursor`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Receiver kinds v1 (file_tail/journald/stdout_stderr) реализованы и задокументированы.
- [ ] Контракт source_id/source_seq/trace_id/retry_count соблюдается и покрыт тестами.
- [ ] Parsing (plain/structured/multiline) детерминирован и покрыт unit tests.
- [ ] Pre-write redaction работает и подтверждён security тестом.
- [ ] Backpressure от spool/outbox реализован и покрыт integration tests.
- [ ] Все `observability_gap.*` события receivers зарегистрированы и имеют runbook.
- [ ] CI gate Stage 18 зелёный.

