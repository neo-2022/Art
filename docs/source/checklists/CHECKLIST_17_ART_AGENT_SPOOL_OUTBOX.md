A) Полный запрет опциональности:
# CHECKLIST 17 — Art Agent Spool/Outbox
Файл: CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение spool политики; изменение recovery; изменение concurrency модели; изменение TTL/DLQ; изменение runbook registry
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

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

- [ ] **1. Сделать:** Реализовать default политику `never_drop_unacked`: при full блокировать receivers + `observability_gap.spool_full` + periodic recheck.
  - [ ] Default policy зафиксирована: `spool_overflow_policy=never_drop_unacked`
  - [ ] При достижении capacity:
    - [ ] приём новых событий от receivers останавливается (stop ingest at source)
    - [ ] existing unacked не удаляются и не перезаписываются
    - [ ] включается periodic recheck каждые 1000 мс
  - [ ] Генерируется `observability_gap.spool_full` (snapshot/stream) с evidence_min:
    - [ ] spool_path
    - [ ] capacity_bytes
    - [ ] used_bytes
    - [ ] backlog_count
    - [ ] trace_id
  - [ ] `observability_gap.spool_full` зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/spool_full.md`
  - [ ] **Проверка (pass/fail):** integration test форсит full и проверяет:
    - [ ] receivers блокируются
    - [ ] recheck работает
    - [ ] событие `observability_gap.spool_full` видно в snapshot/stream.

- [ ] **2. Сделать:** Реализовать альтернативную политику `drop_oldest_when_full`: drop oldest + `data_quality.lossy_spool_drop` + инцидент `lossy_mode_active` + метрики.
  - [ ] Политика включается только через конфиг: `spool_overflow_policy=drop_oldest_when_full`
  - [ ] При full:
    - [ ] удаляется oldest запись (drop oldest)
    - [ ] генерируется `data_quality.lossy_spool_drop` (snapshot/stream)
    - [ ] увеличивается `spool_dropped_total`
    - [ ] создаётся инцидент `lossy_mode_active` с severity не ниже SEV1
    - [ ] инцидент содержит `action_ref=docs/runbooks/lossy_mode_active.md`
  - [ ] `data_quality.lossy_spool_drop` содержит evidence_min:
    - [ ] dropped_count (>=1)
    - [ ] backlog_count
    - [ ] used_bytes
    - [ ] trace_id
  - [ ] **Проверка (pass/fail):** integration test форсит full в режиме drop_oldest и проверяет:
    - [ ] drop oldest реально происходит
    - [ ] `data_quality.lossy_spool_drop` появляется
    - [ ] `spool_dropped_total` растёт
    - [ ] инцидент `lossy_mode_active` создан.

- [ ] **3. Сделать:** Реализовать spool corruption recovery: новый spool + `observability_gap.spool_corrupted` + продолжение работы.
  - [ ] При детекте corruption:
    - [ ] создаётся новый spool (новый каталог/файл, фиксированный алгоритм именования)
    - [ ] старый spool помечается как quarantined (не используется дальше)
    - [ ] ingest от receivers продолжается в новый spool
  - [ ] Генерируется `observability_gap.spool_corrupted` (snapshot/stream) с evidence_min:
    - [ ] old_spool_path
    - [ ] new_spool_path
    - [ ] corruption_type
    - [ ] trace_id
  - [ ] `observability_gap.spool_corrupted` зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/spool_corrupted.md`
  - [ ] **Проверка (pass/fail):** corruption test воспроизводит порчу spool и проверяет:
    - [ ] создание нового spool
    - [ ] продолжение приёма событий
    - [ ] событие `observability_gap.spool_corrupted` видно в snapshot/stream.

- [ ] **4. Сделать:** Реализовать concurrency test: 10 потоков записи в spool → целостность.
  - [ ] тест запускает ровно 10 writer потоков
  - [ ] тест выполняет ≥ 10000 записей суммарно (фиксированный критерий)
  - [ ] тест проверяет инварианты:
    - [ ] отсутствуют “lost records” (счётчик записей совпадает с прочитанными)
    - [ ] ack/seq монотонны на стороне отправки в Core (если применимо к тесту)
    - [ ] spool индекс/метаданные консистентны после завершения
  - [ ] **Проверка (pass/fail):** integration test зелёный в CI и лог фиксирует параметры (threads=10, writes>=10000).

- [ ] **5. Сделать:** Chaos тесты spool/outbox (обязательные, воспроизводимые сценарии).
  - [ ] chaos: kill -9 Agent во время записи
    - [ ] после рестарта данные консистентны
    - [ ] агент продолжает flush в Core
  - [ ] chaos: network loss (Core недоступен)
    - [ ] outbox/spool растёт до лимита
    - [ ] включается backoff
    - [ ] при full отрабатывает политика из шага 1 или 2 (в зависимости от конфига)
  - [ ] chaos: disk full на spool пути
    - [ ] генерируется `observability_gap.spool_disk_full` (snapshot/stream)
    - [ ] событие зарегистрировано в реестре с:
      - [ ] `incident_rule=create_incident_min_sev1`
      - [ ] `action_ref=docs/runbooks/spool_disk_full.md`
  - [ ] chaos: corruption
    - [ ] отрабатывает recovery шага 3
  - [ ] **Проверка (pass/fail):** существует документ `docs/agent/spool_chaos.md` с точными шагами воспроизведения и критериями pass/fail для каждого сценария; минимум 1 chaos smoke прогоняется в CI.

## Документация (RU)
- [ ] docs/agent/spool.md
- [ ] docs/agent/spool_policies.md
- [ ] docs/agent/recovery.md
- [ ] docs/agent/spool_chaos.md
- [ ] docs/runbooks/spool_full.md
- [ ] docs/runbooks/spool_corrupted.md
- [ ] docs/runbooks/spool_disk_full.md
- [ ] docs/runbooks/lossy_mode_active.md

## Тестирование
- [ ] integration: `never_drop_unacked` (шаг 1)
- [ ] integration: `drop_oldest_when_full` (шаг 2)
- [ ] integration: corruption recovery (шаг 3)
- [ ] integration: concurrency 10 writers (шаг 4)
- [ ] chaos: kill -9 + network loss + disk full + corruption (шаг 5)

## CI gate
- [ ] CI job `agent-spool-tests` существует и зелёный (шага 1–4)
- [ ] CI job `agent-spool-chaos-smoke (runtime chaos smoke)` существует и зелёный (выполняет `scripts/tests/agent_spool_chaos_runtime.sh`: kill -9 + full + disk_full + corruption)
- [ ] CI job `stage17-docs-gate` существует и запускает `scripts/ci/check_agent_spool_stage17_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/agent/spool_policies.md` содержит `never_drop_unacked` и `drop_oldest_when_full`
    - [ ] `docs/agent/recovery.md` содержит `spool_corrupted`
    - [ ] `docs/agent/spool_chaos.md` содержит `kill -9` и `disk full`
    - [ ] runbooks содержат `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Default `never_drop_unacked` реализован и подтверждён тестом; `observability_gap.spool_full` зарегистрирован и имеет runbook.
- [ ] `drop_oldest_when_full` реализован и подтверждён тестом; `data_quality.lossy_spool_drop` и инцидент `lossy_mode_active` работают.
- [ ] Corruption recovery детерминирован и подтверждён тестом; `observability_gap.spool_corrupted` зарегистрирован и имеет runbook.
- [ ] Concurrency test (10 потоков) зелёный.
- [ ] Chaos сценарии воспроизводимы и smoke прогоняется в CI.
- [ ] CI gate Stage 17 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
