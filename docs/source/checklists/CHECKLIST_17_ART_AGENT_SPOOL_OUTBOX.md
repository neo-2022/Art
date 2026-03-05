A) Полный запрет опциональности:
# CHECKLIST 17 — Art Agent Spool/Outbox
Файл: CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение spool политики; изменение recovery; изменение concurrency модели; изменение TTL/DLQ; изменение runbook registry

## Цель
Spool однозначен и проверяем: default `never_drop_unacked` блокирует receivers при full; альтернативный `drop_oldest_when_full` включает lossy события и инцидент; recovery при corruption детерминирован; concurrency тест 10 потоков; chaos обязателен; все `observability_gap.*` зарегистрированы с `incident_rule` и `action_ref`.

## Границы
Spool/outbox Agent (локальная очередь, persistence, retry/backoff, flush в Core ingest). Не включает Core storage/ingest, только агентскую часть.

## Зависимости
- CHECKLIST 12 — Art Core Ingest v1 (ack/seq/backpressure)
- CHECKLIST 11 — Art Core Storage v1 (SQLite) (ошибки storage как upstream)
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, incident rules, runbooks)

## Статус перепроверки
- Перепроверка завершена: runtime, тесты, docs и CI gate подтверждены.

## Шаги (строго линейно)

- [x] **1. Сделать:** Реализовать default политику `never_drop_unacked`: при full блокировать receivers + `observability_gap.spool_full` + periodic recheck.
  - [x] Default policy зафиксирована: `spool_overflow_policy=never_drop_unacked`
  - [x] При достижении capacity:
    - [x] приём новых событий от receivers останавливается (stop ingest at source)
    - [x] existing unacked не удаляются и не перезаписываются
    - [x] включается periodic recheck каждые 1000 мс
  - [x] Генерируется `observability_gap.spool_full` (snapshot/stream) с evidence_min:
    - [x] spool_path
    - [x] capacity_bytes
    - [x] used_bytes
    - [x] backlog_count
    - [x] trace_id
  - [x] `observability_gap.spool_full` зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/spool_full.md`
  - [x] **Проверка (pass/fail):** integration test форсит full и проверяет:
    - [x] receivers блокируются
    - [x] recheck работает
    - [x] событие `observability_gap.spool_full` видно в snapshot/stream.

- [x] **2. Сделать:** Реализовать альтернативную политику `drop_oldest_when_full`: drop oldest + `data_quality.lossy_spool_drop` + инцидент `lossy_mode_active` + метрики.
  - [x] Политика включается только через конфиг: `spool_overflow_policy=drop_oldest_when_full`
  - [x] При full:
    - [x] удаляется oldest запись (drop oldest)
    - [x] генерируется `data_quality.lossy_spool_drop` (snapshot/stream)
    - [x] увеличивается `spool_dropped_total`
    - [x] создаётся инцидент `lossy_mode_active` с severity не ниже SEV1
    - [x] инцидент содержит `action_ref=docs/runbooks/lossy_mode_active.md`
  - [x] `data_quality.lossy_spool_drop` содержит evidence_min:
    - [x] dropped_count (>=1)
    - [x] backlog_count
    - [x] used_bytes
    - [x] trace_id
  - [x] **Проверка (pass/fail):** integration test форсит full в режиме drop_oldest и проверяет:
    - [x] drop oldest реально происходит
    - [x] `data_quality.lossy_spool_drop` появляется
    - [x] `spool_dropped_total` растёт
    - [x] инцидент `lossy_mode_active` создан.

- [x] **3. Сделать:** Реализовать spool corruption recovery: новый spool + `observability_gap.spool_corrupted` + продолжение работы.
  - [x] При детекте corruption:
    - [x] создаётся новый spool (новый каталог/файл, фиксированный алгоритм именования)
    - [x] старый spool помечается как quarantined (не используется дальше)
    - [x] ingest от receivers продолжается в новый spool
  - [x] Генерируется `observability_gap.spool_corrupted` (snapshot/stream) с evidence_min:
    - [x] old_spool_path
    - [x] new_spool_path
    - [x] corruption_type
    - [x] trace_id
  - [x] `observability_gap.spool_corrupted` зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/spool_corrupted.md`
  - [x] **Проверка (pass/fail):** corruption test воспроизводит порчу spool и проверяет:
    - [x] создание нового spool
    - [x] продолжение приёма событий
    - [x] событие `observability_gap.spool_corrupted` видно в snapshot/stream.

- [x] **4. Сделать:** Реализовать concurrency test: 10 потоков записи в spool → целостность.
  - [x] тест запускает ровно 10 writer потоков
  - [x] тест выполняет ≥ 10000 записей суммарно (фиксированный критерий)
  - [x] тест проверяет инварианты:
    - [x] отсутствуют “lost records” (счётчик записей совпадает с прочитанными)
    - [x] ack/seq монотонны на стороне отправки в Core (если применимо к тесту)
    - [x] spool индекс/метаданные консистентны после завершения
  - [x] **Проверка (pass/fail):** integration test зелёный в CI и лог фиксирует параметры (threads=10, writes>=10000).

- [x] **5. Сделать:** Chaos тесты spool/outbox (обязательные, воспроизводимые сценарии).
  - [x] chaos: kill -9 Agent во время записи
    - [x] после рестарта данные консистентны
    - [x] агент продолжает flush в Core
  - [x] chaos: network loss (Core недоступен)
    - [x] outbox/spool растёт до лимита
    - [x] включается backoff
    - [x] при full отрабатывает политика из шага 1 или 2 (в зависимости от конфига)
  - [x] chaos: disk full на spool пути
    - [x] генерируется `observability_gap.spool_disk_full` (snapshot/stream)
    - [x] событие зарегистрировано в реестре с:
      - [x] `incident_rule=create_incident_min_sev1`
      - [x] `action_ref=docs/runbooks/spool_disk_full.md`
  - [x] chaos: corruption
    - [x] отрабатывает recovery шага 3
  - [x] **Проверка (pass/fail):** существует документ `docs/agent/spool_chaos.md` с точными шагами воспроизведения и критериями pass/fail для каждого сценария; минимум 1 chaos smoke прогоняется в CI.

## Документация (RU)
- [x] docs/agent/spool.md
- [x] docs/agent/spool_policies.md
- [x] docs/agent/recovery.md
- [x] docs/agent/spool_chaos.md
- [x] docs/runbooks/spool_full.md
- [x] docs/runbooks/spool_corrupted.md
- [x] docs/runbooks/spool_disk_full.md
- [x] docs/runbooks/lossy_mode_active.md

## Тестирование
- [x] integration: `never_drop_unacked` (шаг 1)
- [x] integration: `drop_oldest_when_full` (шаг 2)
- [x] integration: corruption recovery (шаг 3)
- [x] integration: concurrency 10 writers (шаг 4)
- [x] chaos: kill -9 + network loss + disk full + corruption (шаг 5)

## CI gate
- [x] CI job `agent-spool-tests` существует и зелёный (шага 1–4)
- [x] CI job `agent-spool-chaos-smoke` существует и зелёный (smoke подмножество шага 5: kill -9 + network loss)
- [x] CI job `stage17-docs-gate` существует и запускает `scripts/ci/check_agent_spool_stage17_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/agent/spool_policies.md` содержит `never_drop_unacked` и `drop_oldest_when_full`
    - [x] `docs/agent/recovery.md` содержит `spool_corrupted`
    - [x] `docs/agent/spool_chaos.md` содержит `kill -9` и `disk full`
    - [x] runbooks содержат `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Default `never_drop_unacked` реализован и подтверждён тестом; `observability_gap.spool_full` зарегистрирован и имеет runbook.
- [x] `drop_oldest_when_full` реализован и подтверждён тестом; `data_quality.lossy_spool_drop` и инцидент `lossy_mode_active` работают.
- [x] Corruption recovery детерминирован и подтверждён тестом; `observability_gap.spool_corrupted` зарегистрирован и имеет runbook.
- [x] Concurrency test (10 потоков) зелёный.
- [x] Chaos сценарии воспроизводимы и smoke прогоняется в CI.
- [x] CI gate Stage 17 зелёный.

