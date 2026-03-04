A) Полный запрет опциональности:
# CHECKLIST 11 — Art Core Storage v1 (SQLite)
Файл: CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (перепроверка, reopened)  
Триггер пересмотра: изменение схемы БД; изменение recovery; изменение политики backup/restore; изменение политики archive/retention; изменение VACUUM расписания

## Цель
Сделать storage однозначно устойчивым: алгоритм WAL corruption recovery, тесты конкурентного доступа, расписание VACUUM, обязательные chaos сценарии (kill -9, disk full, WAL corruption), и события `observability_gap.*` с runbook.

## Границы
Только storage Core (SQLite): файлы БД, WAL, backup/restore, housekeeping (VACUUM), поведение при corruption/переполнении диска.

## Зависимости
- CHECKLIST 08 — Contracts + OpenAPI + codegen + schema registry
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 03 — Regional profiles
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, incident rules, runbooks)

## Статус перепроверки
- Закрытие этапа снято: заявленные тесты/CI или runtime-реализация не подтверждены полностью по факту кода и workflow.
- До полного соответствия все пункты этапа считаются незакрытыми.

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать алгоритм WAL corruption recovery (детерминированный).
  - [ ] При детекте corruption:
    - [ ] ingest отвечает HTTP 503
    - [ ] ответ содержит `retry_after_ms` (число >= 0)
  - [ ] Генерируется событие `observability_gap.storage_corrupted` и оно попадает в snapshot/stream
  - [ ] `observability_gap.storage_corrupted` содержит evidence_min:
    - [ ] db_path
    - [ ] corruption_type (строка)
    - [ ] sqlite_error (строка)
    - [ ] last_ok_backup_id (строка или `none`)
    - [ ] trace_id
  - [ ] Авто-восстановление:
    - [ ] выполняется restore из последнего валидного backup
    - [ ] после restore выполняется integrity check (фиксированная команда/процедура)
    - [ ] при успехе ingest возвращается в нормальный режим
  - [ ] При неуспехе авто-восстановления:
    - [ ] Core переводится в режим `read_only`
    - [ ] ingest продолжает отвечать 503 с `retry_after_ms`
    - [ ] генерируется событие `observability_gap.storage_read_only` (snapshot/stream)
  - [ ] `observability_gap.storage_corrupted` и `observability_gap.storage_read_only` зарегистрированы в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/ops/storage_corruption_runbook.md`
  - [ ] **Проверка (pass/fail):** существует `docs/ops/storage_corruption_runbook.md`, и он описывает шаги выше в указанном порядке (включая 503+retry_after_ms, события, restore, integrity check, read_only fallback).

- [ ] **2. Сделать:** Зафиксировать backup/restore политику SQLite (частота + формат + хранение).
  - [ ] backup создаётся по расписанию (частота задана числом + единицей)
  - [ ] хранится минимум N последних backup (N задан числом)
  - [ ] путь хранения фиксирован и зависит от профиля (Stage 03), но задаётся конкретным значением в профиле
  - [ ] backup включает WAL/метаданные, достаточные для восстановления
  - [ ] restore процедура включает integrity check после восстановления
  - [ ] **Проверка (pass/fail):** существует `docs/ops/backup_restore_sqlite.md` и содержит все пункты выше явно (с конкретными значениями частоты/N/пути).

- [ ] **3. Сделать:** Реализовать concurrency тест многопоточной записи/чтения SQLite.
  - [ ] тест запускает ≥ 8 параллельных writer потоков
  - [ ] тест запускает ≥ 4 параллельных reader потоков
  - [ ] тест выполняется ≥ 60 секунд (или ≥ 10000 операций; выбрать один критерий и зафиксировать)
  - [ ] тест проверяет отсутствие “database is locked” как фатальной ошибки (ошибки должны быть обработаны по политике ретраев)
  - [ ] тест проверяет корректность данных (счётчики accepted/committed совпадают по инварианту)
  - [ ] **Проверка (pass/fail):** integration тест зелёный в CI и его лог/вывод фиксирует параметры (writers/readers/длительность).

- [ ] **4. Сделать:** Реализовать VACUUM по расписанию: каждое воскресенье 03:30 (systemd timer).
  - [ ] существует systemd unit `art-vacuum.service`
  - [ ] существует systemd timer `art-vacuum.timer`
  - [ ] timer настроен на воскресенье 03:30 (локальное время системы)
  - [ ] VACUUM выполняется в safe-режиме (не во время активного ingest; правило описано и реализовано)
  - [ ] успешный VACUUM логируется (без PII)
  - [ ] при ошибке VACUUM генерируется `observability_gap.storage_vacuum_failed` (snapshot/stream) с evidence_min
  - [ ] `observability_gap.storage_vacuum_failed` зарегистрировано в реестре с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/ops/vacuum_schedule.md`
  - [ ] **Проверка (pass/fail):** наличие unit/timer в репозитории + smoke запуск на тестовой БД подтверждает, что VACUUM выполняется.

- [ ] **5. Сделать:** Реализовать chaos тесты storage (обязательные сценарии) и сделать их воспроизводимыми.
  - [ ] chaos: kill -9 Core во время ingest
    - [ ] после рестарта Core: данные консистентны (integrity check pass)
    - [ ] ingest восстанавливается и принимает события
  - [ ] chaos: disk full (на пути storage)
    - [ ] ingest отвечает 503 + retry_after_ms
    - [ ] генерируется `observability_gap.storage_disk_full` (snapshot/stream)
    - [ ] `observability_gap.storage_disk_full` зарегистрировано в реестре с:
      - [ ] `incident_rule=create_incident_min_sev1`
      - [ ] `action_ref=docs/ops/storage.md` (или отдельный runbook; выбрать один файл и зафиксировать)
  - [ ] chaos: WAL corruption
    - [ ] воспроизводимый способ порчи WAL описан
    - [ ] отрабатывает алгоритм шага 1 (503+retry_after_ms + события + restore + integrity check)
  - [ ] **Проверка (pass/fail):** существует `docs/ops/storage.md` (или отдельный документ) с точными шагами воспроизведения каждого сценария и критериями pass/fail; минимум smoke chaos прогоняется в CI.

## Документация (RU)
- [ ] docs/core/storage.md
- [ ] docs/ops/backup_restore_sqlite.md
- [ ] docs/ops/storage_corruption_runbook.md
- [ ] docs/ops/vacuum_schedule.md
- [ ] docs/ops/storage.md

## Тестирование
- [ ] integration: concurrency (шаг 3)
- [ ] chaos: kill -9 (шаг 5)
- [ ] chaos: disk full (шаг 5)
- [ ] chaos: WAL corruption (шаг 5)

## CI gate
- [ ] CI job `storage-integration` существует и запускает concurrency тест; job зелёный
- [ ] CI job `storage-chaos-smoke` существует и запускает минимум 1 smoke прогон chaos сценариев; job зелёный
- [ ] CI job `stage11-docs-gate` существует и запускает `scripts/ci/check_storage_stage11_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/ops/storage_corruption_runbook.md` содержит `HTTP 503` и `retry_after_ms` и `read_only`
    - [ ] `docs/ops/vacuum_schedule.md` содержит `Sunday` или `воскресенье` и `03:30`
    - [ ] `docs/ops/backup_restore_sqlite.md` содержит `integrity check`
  - [ ] exit 1 при нарушении

## DoD
- [ ] Recovery по corruption детерминирован и задокументирован; события `observability_gap.*` зарегистрированы и имеют runbook.
- [ ] Backup/restore политика определена и выполнима.
- [ ] Concurrency тест зелёный в CI.
- [ ] VACUUM timer/unit существуют и smoke проверены.
- [ ] Chaos сценарии воспроизводимы и имеют pass/fail критерии; минимум smoke прогоняется в CI.
- [ ] CI gate Stage 11 зелёный.

