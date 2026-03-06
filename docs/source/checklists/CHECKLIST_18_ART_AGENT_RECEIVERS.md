A) Полный запрет опциональности:
# CHECKLIST 18 — Art Agent Receivers v1
Файл: CHECKLIST_18_ART_AGENT_RECEIVERS.md  
Последняя актуализация: 2026-03-06  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение формата RawEvent; изменение redaction rules; изменение spool/outbox политики; добавление/изменение receiver kinds; изменение политики multiline/парсинга; изменение source coverage проекта
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Receivers в агенте однозначны и проверяемы: фиксированный список receiver kinds v1, детерминированный контракт `source_id/source_seq`, корректный парсинг (включая multiline), pre-write redaction, backpressure от spool/outbox, обязательные `observability_gap.*`/`data_quality.*` события с runbook, и покрытие всех доступных сигналов проекта/окружения через явную source coverage matrix.

## Границы
Только слой Receivers в Art Agent: чтение источников, нормализация в RawEvent, привязка `source_id/source_seq`, отправка в spool/outbox.  
Core ingest/storage/pipeline — в других чек-листах.

## Зависимости
- CHECKLIST 17 — Art Agent Spool/Outbox
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 09 — Telemetry alignment (OTel/OTLP)
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, runbooks)

## Статус перепроверки
- Перепроверка завершена: runtime, тесты, docs и CI gate подтверждены.

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать receiver API/контракт и список receiver kinds v1 (ровно фиксированный набор).
  - [ ] `receiver_kind` (enum) фиксирован и содержит ровно:
    - [ ] `file_tail`
    - [ ] `journald`
    - [ ] `systemd_unit`
    - [ ] `proc_probe`
    - [ ] `net_probe`
    - [ ] `stdout_stderr` (обёртка запуска процесса/pipe)
    - [ ] `otlp_logs`
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
    - [ ] `systemd_unit`: `systemd:<unit_name>`
    - [ ] `proc_probe`: `proc:<target_name>`
    - [ ] `net_probe`: `net:<target_name>`
    - [ ] `stdout_stderr`: `proc:<command_id>`
    - [ ] `otlp_logs`: `otlp:<listener_id>`
  - [ ] **Проверка (pass/fail):** существует `docs/agent/receivers.md`, содержит enum, контракт полей и правила source_id.

- [ ] **2. Сделать:** Зафиксировать source coverage matrix агента как обязательный закон этапа 18.
  - [ ] существует `docs/agent/receiver_source_coverage.md`
  - [ ] matrix содержит минимум классы источников:
    - [ ] `journald/systemd`
    - [ ] `files/logs`
    - [ ] `stdout/stderr wrapper`
    - [ ] `process probes`
    - [ ] `port/network/http probes`
    - [ ] `OTLP logs`
  - [ ] для каждой строки зафиксированы:
    - [ ] `receiver_kind`
    - [ ] `mechanism`
    - [ ] `source_id_pattern`
    - [ ] `persistence_mode`
    - [ ] `gap_events`
    - [ ] `privacy_boundary`
  - [ ] **Проверка (pass/fail):** документ существует и содержит все обязательные классы и поля.

- [ ] **3. Сделать:** Реализовать pre-write redaction в receivers ДО записи в spool/outbox.
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

- [ ] **4. Сделать:** Реализовать parsing policy: plain + structured + multiline (фиксированное поведение).
  - [ ] Базовый режим: line-based (каждая строка → 1 RawEvent)
  - [ ] Structured режим (JSON line):
    - [ ] если строка валидный JSON object → кладётся в `payload.structured` (объект)
    - [ ] исходная строка сохраняется как `payload.raw_line` (строка)
  - [ ] Multiline режим фиксирован:
    - [ ] начало события: regex `^(\\S+\\s+\\S+|{)` (одно фиксированное правило)
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

- [ ] **5. Сделать:** Реализовать backpressure receivers от spool/outbox (строгое поведение).
  - [ ] Default: при `spool_overflow_policy=never_drop_unacked`:
    - [ ] receiver прекращает чтение источника (pause)
    - [ ] генерируется `observability_gap.receiver_paused_spool_full` (snapshot/stream)
  - [ ] При `spool_overflow_policy=drop_oldest_when_full`:
    - [ ] receiver продолжает чтение
    - [ ] потери фиксируются событиями lossy из Stage 17 (spool drop) + локально `data_quality.receiver_lossy_mode_active` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] форсит spool full в `never_drop_unacked` и проверяет pause + `observability_gap.receiver_paused_spool_full`
    - [ ] форсит spool full в `drop_oldest_when_full` и проверяет продолжение чтения + lossy события.

- [ ] **6. Сделать:** Реализовать receiver `file_tail` (log rotation + offset persistence).
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

- [ ] **7. Сделать:** Реализовать receiver `journald` (cursor persistence).
  - [ ] фильтр фиксирован: `UNIT=<service>` (одно фиксированное решение)
  - [ ] хранит journald cursor в state-файле
  - [ ] перезапуск агента продолжает чтение с сохранённого cursor
  - [ ] read error → `observability_gap.receiver_read_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] читает записи из journald
    - [ ] после рестарта продолжает с cursor (не дублирует и не пропускает)
    - [ ] source_seq монотонен.

- [ ] **8. Сделать:** Реализовать receiver `systemd_unit` для статусных переходов unit state.
  - [ ] receiver фиксирует минимум события:
    - [ ] `service_started`
    - [ ] `service_stopped`
    - [ ] `service_failed`
    - [ ] `service_restart_loop`
  - [ ] receiver использует systemd metadata без парсинга journald как единственного источника истины по state transitions
  - [ ] ошибка чтения состояния или недоступность systemd API порождает `observability_gap.receiver_read_failed`
  - [ ] **Проверка (pass/fail):** integration test подтверждает детект unit state transitions и монотонность `source_seq`.

- [ ] **9. Сделать:** Реализовать receivers `proc_probe` и `net_probe` как обязательные инфраструктурные probes.
  - [ ] `proc_probe` фиксирует минимум:
    - [ ] pid presence/absence
    - [ ] exit state (если доступен)
    - [ ] basic cpu/rss snapshot (если доступно)
  - [ ] `net_probe` фиксирует минимум:
    - [ ] tcp port reachability
    - [ ] http status / latency для health/openapi endpoints
    - [ ] timeout / connection refused / dns error как отдельные причины
  - [ ] probe failures порождают `observability_gap.receiver_probe_failed`
  - [ ] недоступность target порождает `observability_gap.receiver_target_unreachable`
  - [ ] **Проверка (pass/fail):** integration tests подтверждают success/fail/timeout/refused ветки и генерацию обоих gap events.

- [ ] **10. Сделать:** Реализовать receiver `stdout_stderr` (wrapper).
  - [ ] запускает процесс по фиксированному `command_id`
  - [ ] читает stdout и stderr как два канала:
    - [ ] `payload.stream="stdout"` / `payload.stream="stderr"`
  - [ ] exit non-zero → `observability_gap.receiver_process_exited` (snapshot/stream)
  - [ ] spawn error → `observability_gap.receiver_process_spawn_failed` (snapshot/stream)
  - [ ] **Проверка (pass/fail):** integration test:
    - [ ] stdout/stderr события приходят
    - [ ] non-zero exit порождает `observability_gap.receiver_process_exited`.

- [ ] **11. Сделать:** Реализовать receiver `otlp_logs` как agent-side sidecar ingress path.
  - [ ] принимаются только OTLP logs
  - [ ] receiver интегрирован с лимитами и backpressure контуром Stage 09
  - [ ] receiver не теряет correlation fields (`trace_id`, `span_id`, `correlation_id`, `run_id`, `node_id`) при наличии во входящем payload
  - [ ] receiver при недоступности listener/config problem генерирует `observability_gap.receiver_config_invalid` или `observability_gap.receiver_read_failed`
  - [ ] **Проверка (pass/fail):** runtime/integration test подтверждает ingest OTLP logs через Agent receiver и сохранение correlation.

- [ ] **12. Сделать:** Зарегистрировать все receiver gap/quality события в реестре `observability_gap_registry.md` и зафиксировать incident_rule + runbook.
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
  - [ ] `observability_gap.receiver_probe_failed`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_probe_failed.md`
  - [ ] `observability_gap.receiver_target_unreachable`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_target_unreachable.md`
  - [ ] `observability_gap.receiver_config_invalid`:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/receiver_config_invalid.md`
  - [ ] **Проверка (pass/fail):** реестр содержит все события выше с `incident_rule` и `action_ref`; все runbook файлы существуют.

- [ ] **13. Сделать:** RU-дока receivers: конфиг, state, примеры, ограничения.
  - [ ] `docs/agent/receivers.md` содержит контракт (шаг 1)
  - [ ] `docs/agent/receivers_config.md` содержит фиксированный формат конфига receivers и:
    - [ ] пример для file_tail
    - [ ] пример для journald
    - [ ] пример для systemd_unit
    - [ ] пример для proc_probe
    - [ ] пример для net_probe
    - [ ] пример для stdout_stderr
    - [ ] пример для otlp_logs
  - [ ] `docs/agent/receivers_state.md` описывает state файлы (offset/cursor) и их формат
  - [ ] **Проверка (pass/fail):** документы существуют и содержат указанные примеры и поля.

## Документация (RU)
- [ ] docs/agent/receivers.md
- [ ] docs/agent/receivers_config.md
- [ ] docs/agent/receiver_source_coverage.md
- [ ] docs/agent/receivers_state.md
- [ ] docs/agent/receivers_chaos.md
- [ ] docs/runbooks/receiver_paused_spool_full.md
- [ ] docs/runbooks/receiver_permission_denied.md
- [ ] docs/runbooks/receiver_read_failed.md
- [ ] docs/runbooks/receiver_process_spawn_failed.md
- [ ] docs/runbooks/receiver_process_exited.md
- [ ] docs/runbooks/receiver_probe_failed.md
- [ ] docs/runbooks/receiver_target_unreachable.md
- [ ] docs/runbooks/receiver_config_invalid.md

## Тестирование
- [ ] unit: parsing (plain/structured/multiline) + truncation + parse_failed
- [ ] security: pre-write redaction + `privacy.redaction_applied`
- [ ] integration: file_tail (offset + rotation + permission denied)
- [ ] integration: journald (cursor persistence)
- [ ] integration: systemd_unit (state transitions)
- [ ] integration: proc_probe + net_probe (success/fail/timeout/refused)
- [ ] integration: stdout_stderr (spawn + exit non-zero)
- [ ] integration: otlp_logs via Agent receiver (including correlation preservation)
- [ ] integration: backpressure pause/continue по политикам spool (Stage 17)
- [ ] chaos runtime matrix: `scripts/tests/agent_receivers_chaos_runtime.sh` (permission denied/spawn failed/probe failed/target unreachable/parse failed/multiline oversize/unsupported kind/redaction/config invalid)

## CI gate
- [ ] CI job `agent-receivers-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `agent-receivers-chaos-runtime` существует и запускает `scripts/tests/agent_receivers_chaos_runtime.sh`
- [ ] CI job `stage18-docs-gate` существует и запускается на PR в main
- [ ] `stage18-docs-gate` запускает `scripts/ci/check_agent_receivers_stage18_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/agent/receivers.md` содержит `receiver_kind` и `source_id` и `source_seq`
    - [ ] `docs/agent/receivers_config.md` содержит `file_tail` и `journald` и `systemd_unit` и `proc_probe` и `net_probe` и `stdout_stderr` и `otlp_logs`
    - [ ] `docs/agent/receiver_source_coverage.md` содержит `journald/systemd` и `files/logs` и `process probes` и `OTLP logs`
    - [ ] `docs/agent/receivers_state.md` содержит `offset` и `cursor`
    - [ ] `docs/agent/receivers_chaos.md` содержит `agent_receivers_chaos_runtime.sh` и `receiver_process_spawn_failed` и `receiver_probe_failed`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Receiver kinds v1 (`file_tail`, `journald`, `systemd_unit`, `proc_probe`, `net_probe`, `stdout_stderr`, `otlp_logs`) реализованы и задокументированы.
- [ ] Контракт source_id/source_seq/trace_id/retry_count соблюдается и покрыт тестами.
- [ ] Source coverage matrix агента фиксирует полный охват доступных сигналов проекта/окружения.
- [ ] Parsing (plain/structured/multiline) детерминирован и покрыт unit tests.
- [ ] Pre-write redaction работает и подтверждён security тестом.
- [ ] Backpressure от spool/outbox реализован и покрыт integration tests.
- [ ] Все `observability_gap.*` события receivers зарегистрированы и имеют runbook.
- [ ] CI gate Stage 18 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
