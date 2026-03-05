A) Полный запрет опциональности:
# CHECKLIST 18 — Art Agent Receivers v1
Файл: CHECKLIST_18_ART_AGENT_RECEIVERS.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
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
- Перепроверка завершена: runtime, тесты, docs и CI gate подтверждены.

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать receiver API/контракт и список receiver kinds v1 (ровно фиксированный набор).
  - [x] `receiver_kind` (enum) фиксирован и содержит ровно:
    - [x] `file_tail`
    - [x] `journald`
    - [x] `stdout_stderr` (обёртка запуска процесса/pipe)
  - [x] Каждый receiver генерирует RawEvent со строгими полями:
    - [x] `source_id` (строка, уникальна в рамках агента)
    - [x] `source_seq` (целое >= 0, монотонно растёт для данного source_id)
    - [x] `source_ts_ms` (целое >= 0)
    - [x] `receiver_kind` (одно из enum)
    - [x] `trace_id` (всегда; генерируется при отсутствии)
    - [x] `retry_count` (всегда; целое >= 0)
  - [x] Правило уникальности `source_id` фиксировано:
    - [x] `file_tail`: `file:<abs_path>`
    - [x] `journald`: `journald:<unit_or_matcher_id>`
    - [x] `stdout_stderr`: `proc:<command_id>`
  - [x] **Проверка (pass/fail):** существует `docs/agent/receivers.md`, содержит enum, контракт полей и правила source_id.

- [x] **2. Сделать:** Реализовать pre-write redaction в receivers ДО записи в spool/outbox.
  - [x] redaction применяется к:
    - [x] `message`
    - [x] `payload` (включая structured fields)
    - [x] `ctx` (если заполняется)
    - [x] метаданным receiver (например file path в message запрещён; допускается только в `source_id`)
  - [x] redaction использует конфиг rules Stage 02
  - [x] при фактической правке данных генерируется `privacy.redaction_applied` (snapshot/stream)
  - [x] **Проверка (pass/fail):** security test подаёт секрет/PII на вход receiver и проверяет:
    - [x] в spool/outbox нет исходного секрета
    - [x] есть маска/удаление
    - [x] `privacy.redaction_applied` сработал.

- [x] **3. Сделать:** Реализовать parsing policy: plain + structured + multiline (фиксированное поведение).
  - [x] Базовый режим: line-based (каждая строка → 1 RawEvent)
  - [x] Structured режим (JSON line):
    - [x] если строка валидный JSON object → кладётся в `payload.structured` (объект)
    - [x] исходная строка сохраняется как `payload.raw_line` (строка)
  - [x] Multiline режим фиксирован:
    - [x] начало события: regex `^(\S+\s+\S+|{)` (одно фиксированное правило)
    - [x] продолжение: строки до следующего “начала”
    - [x] max_lines_per_event=50
    - [x] max_event_bytes=65536
  - [x] при превышении лимитов multiline генерируется `data_quality.receiver_multiline_truncated` (snapshot/stream)
  - [x] при ошибке парсинга structured JSON генерируется `data_quality.receiver_parse_failed` (snapshot/stream)
  - [x] **Проверка (pass/fail):** unit tests покрывают:
    - [x] plain lines
    - [x] structured JSON line success
    - [x] structured JSON parse fail → событие `data_quality.receiver_parse_failed`
    - [x] multiline сборка
    - [x] multiline truncation → событие `data_quality.receiver_multiline_truncated`.

- [x] **4. Сделать:** Реализовать backpressure receivers от spool/outbox (строгое поведение).
  - [x] Default: при `spool_overflow_policy=never_drop_unacked`:
    - [x] receiver прекращает чтение источника (pause)
    - [x] генерируется `observability_gap.receiver_paused_spool_full` (snapshot/stream)
  - [x] При `spool_overflow_policy=drop_oldest_when_full`:
    - [x] receiver продолжает чтение
    - [x] потери фиксируются событиями lossy из Stage 17 (spool drop) + локально `data_quality.receiver_lossy_mode_active` (snapshot/stream)
  - [x] **Проверка (pass/fail):** integration test:
    - [x] форсит spool full в `never_drop_unacked` и проверяет pause + `observability_gap.receiver_paused_spool_full`
    - [x] форсит spool full в `drop_oldest_when_full` и проверяет продолжение чтения + lossy события.

- [x] **5. Сделать:** Реализовать receiver `file_tail` (log rotation + offset persistence).
  - [x] читает файл по абсолютному пути
  - [x] хранит offset в state-файле (фиксированный путь и формат описаны)
  - [x] обрабатывает log rotation:
    - [x] inode change → продолжает с 0 нового файла
    - [x] старый inode дочитывается до EOF, затем переключение (одно фиксированное поведение)
  - [x] permission denied → `observability_gap.receiver_permission_denied` (snapshot/stream)
  - [x] read error → `observability_gap.receiver_read_failed` (snapshot/stream)
  - [x] **Проверка (pass/fail):** integration tests:
    - [x] tail читает строки и source_seq монотонен
    - [x] rotation сценарий проходит и не теряет порядок source_seq
    - [x] permission denied вызывает `observability_gap.receiver_permission_denied`.

- [x] **6. Сделать:** Реализовать receiver `journald` (cursor persistence).
  - [x] фильтр фиксирован: `UNIT=<service>` (одно фиксированное решение)
  - [x] хранит journald cursor в state-файле
  - [x] перезапуск агента продолжает чтение с сохранённого cursor
  - [x] read error → `observability_gap.receiver_read_failed` (snapshot/stream)
  - [x] **Проверка (pass/fail):** integration test:
    - [x] читает записи из journald
    - [x] после рестарта продолжает с cursor (не дублирует и не пропускает)
    - [x] source_seq монотонен.

- [x] **7. Сделать:** Реализовать receiver `stdout_stderr` (wrapper).
  - [x] запускает процесс по фиксированному `command_id`
  - [x] читает stdout и stderr как два канала:
    - [x] `payload.stream="stdout"` / `payload.stream="stderr"`
  - [x] exit non-zero → `observability_gap.receiver_process_exited` (snapshot/stream)
  - [x] spawn error → `observability_gap.receiver_process_spawn_failed` (snapshot/stream)
  - [x] **Проверка (pass/fail):** integration test:
    - [x] stdout/stderr события приходят
    - [x] non-zero exit порождает `observability_gap.receiver_process_exited`.

- [x] **8. Сделать:** Зарегистрировать все receiver gap/quality события в реестре `observability_gap_registry.md` и зафиксировать incident_rule + runbook.
  - [x] `observability_gap.receiver_paused_spool_full`:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/receiver_paused_spool_full.md`
  - [x] `observability_gap.receiver_permission_denied`:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/receiver_permission_denied.md`
  - [x] `observability_gap.receiver_read_failed`:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/receiver_read_failed.md`
  - [x] `observability_gap.receiver_process_spawn_failed`:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/receiver_process_spawn_failed.md`
  - [x] `observability_gap.receiver_process_exited`:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/receiver_process_exited.md`
  - [x] **Проверка (pass/fail):** реестр содержит все события выше с `incident_rule` и `action_ref`; все runbook файлы существуют.

- [x] **9. Сделать:** RU-дока receivers: конфиг, state, примеры, ограничения.
  - [x] `docs/agent/receivers.md` содержит контракт (шаг 1)
  - [x] `docs/agent/receivers_config.md` содержит фиксированный формат конфига receivers и:
    - [x] пример для file_tail
    - [x] пример для journald
    - [x] пример для stdout_stderr
  - [x] `docs/agent/receivers_state.md` описывает state файлы (offset/cursor) и их формат
  - [x] **Проверка (pass/fail):** документы существуют и содержат указанные примеры и поля.

## Документация (RU)
- [x] docs/agent/receivers.md
- [x] docs/agent/receivers_config.md
- [x] docs/agent/receivers_state.md
- [x] docs/agent/receivers_chaos.md
- [x] docs/runbooks/receiver_paused_spool_full.md
- [x] docs/runbooks/receiver_permission_denied.md
- [x] docs/runbooks/receiver_read_failed.md
- [x] docs/runbooks/receiver_process_spawn_failed.md
- [x] docs/runbooks/receiver_process_exited.md

## Тестирование
- [x] unit: parsing (plain/structured/multiline) + truncation + parse_failed
- [x] security: pre-write redaction + `privacy.redaction_applied`
- [x] integration: file_tail (offset + rotation + permission denied)
- [x] integration: journald (cursor persistence)
- [x] integration: stdout_stderr (spawn + exit non-zero)
- [x] integration: backpressure pause/continue по политикам spool (Stage 17)
- [x] chaos runtime matrix: `scripts/tests/agent_receivers_chaos_runtime.sh` (permission denied/spawn failed/parse failed/multiline oversize/unsupported kind/redaction)

## CI gate
- [x] CI job `agent-receivers-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `agent-receivers-chaos-runtime` существует и запускает `scripts/tests/agent_receivers_chaos_runtime.sh`
- [x] CI job `stage18-docs-gate` существует и запускается на PR в main
- [x] `stage18-docs-gate` запускает `scripts/ci/check_agent_receivers_stage18_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/agent/receivers.md` содержит `receiver_kind` и `source_id` и `source_seq`
    - [x] `docs/agent/receivers_config.md` содержит `file_tail` и `journald` и `stdout_stderr`
    - [x] `docs/agent/receivers_state.md` содержит `offset` и `cursor`
    - [x] `docs/agent/receivers_chaos.md` содержит `agent_receivers_chaos_runtime.sh` и `receiver_process_spawn_failed`
    - [x] runbooks содержат `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Receiver kinds v1 (file_tail/journald/stdout_stderr) реализованы и задокументированы.
- [x] Контракт source_id/source_seq/trace_id/retry_count соблюдается и покрыт тестами.
- [x] Parsing (plain/structured/multiline) детерминирован и покрыт unit tests.
- [x] Pre-write redaction работает и подтверждён security тестом.
- [x] Backpressure от spool/outbox реализован и покрыт integration tests.
- [x] Все `observability_gap.*` события receivers зарегистрированы и имеют runbook.
- [x] CI gate Stage 18 зелёный.
