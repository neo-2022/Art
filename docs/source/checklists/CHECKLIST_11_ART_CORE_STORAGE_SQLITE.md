A) Полный запрет опциональности:
# CHECKLIST 11 — Art Core Storage v1 (SQLite)
Файл: CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05 (pass)  
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
- Этап подтверждён проверками runtime+docs+CI gate.

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать алгоритм WAL corruption recovery (детерминированный).
  - [x] При детекте corruption:
    - [x] ingest отвечает HTTP 503
    - [x] ответ содержит `retry_after_ms` (число >= 0)
  - [x] Генерируется событие `observability_gap.storage_corrupted` и оно попадает в snapshot/stream
  - [x] `observability_gap.storage_corrupted` содержит evidence_min:
    - [x] db_path
    - [x] corruption_type (строка)
    - [x] sqlite_error (строка)
    - [x] last_ok_backup_id (строка или `none`)
    - [x] trace_id
  - [x] Авто-восстановление:
    - [x] выполняется restore из последнего валидного backup
    - [x] после restore выполняется integrity check (фиксированная команда/процедура)
    - [x] при успехе ingest возвращается в нормальный режим
  - [x] При неуспехе авто-восстановления:
    - [x] Core переводится в режим `read_only`
    - [x] ingest продолжает отвечать 503 с `retry_after_ms`
    - [x] генерируется событие `observability_gap.storage_read_only` (snapshot/stream)
  - [x] `observability_gap.storage_corrupted` и `observability_gap.storage_read_only` зарегистрированы в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/ops/storage_corruption_runbook.md`
  - [x] **Проверка (pass/fail):** существует `docs/ops/storage_corruption_runbook.md`, и он описывает шаги выше в указанном порядке (включая 503+retry_after_ms, события, restore, integrity check, read_only fallback).

- [x] **2. Сделать:** Зафиксировать backup/restore политику SQLite (частота + формат + хранение).
  - [x] backup создаётся по расписанию (частота задана числом + единицей)
  - [x] хранится минимум N последних backup (N задан числом)
  - [x] путь хранения фиксирован и зависит от профиля (Stage 03), но задаётся конкретным значением в профиле
  - [x] backup включает WAL/метаданные, достаточные для восстановления
  - [x] restore процедура включает integrity check после восстановления
  - [x] **Проверка (pass/fail):** существует `docs/ops/backup_restore_sqlite.md` и содержит все пункты выше явно (с конкретными значениями частоты/N/пути).

- [x] **3. Сделать:** Реализовать concurrency тест многопоточной записи/чтения SQLite.
  - [x] тест запускает ≥ 8 параллельных writer потоков
  - [x] тест запускает ≥ 4 параллельных reader потоков
  - [x] тест выполняется ≥ 60 секунд (или ≥ 10000 операций; выбрать один критерий и зафиксировать)
  - [x] тест проверяет отсутствие “database is locked” как фатальной ошибки (ошибки должны быть обработаны по политике ретраев)
  - [x] тест проверяет корректность данных (счётчики accepted/committed совпадают по инварианту)
  - [x] **Проверка (pass/fail):** integration тест зелёный в CI и его лог/вывод фиксирует параметры (writers/readers/длительность).

- [x] **4. Сделать:** Реализовать VACUUM по расписанию: каждое воскресенье 03:30 (systemd timer).
  - [x] существует systemd unit `art-vacuum.service`
  - [x] существует systemd timer `art-vacuum.timer`
  - [x] timer настроен на воскресенье 03:30 (локальное время системы)
  - [x] VACUUM выполняется в safe-режиме (не во время активного ingest; правило описано и реализовано)
  - [x] успешный VACUUM логируется (без PII)
  - [x] при ошибке VACUUM генерируется `observability_gap.storage_vacuum_failed` (snapshot/stream) с evidence_min
  - [x] `observability_gap.storage_vacuum_failed` зарегистрировано в реестре с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/ops/vacuum_schedule.md`
  - [x] **Проверка (pass/fail):** наличие unit/timer в репозитории + smoke запуск на тестовой БД подтверждает, что VACUUM выполняется.

- [x] **5. Сделать:** Реализовать chaos тесты storage (обязательные сценарии) и сделать их воспроизводимыми.
  - [x] chaos: kill -9 Core во время ingest
    - [x] после рестарта Core: данные консистентны (integrity check pass)
    - [x] ingest восстанавливается и принимает события
  - [x] chaos: disk full (на пути storage)
    - [x] ingest отвечает 503 + retry_after_ms
    - [x] генерируется `observability_gap.storage_disk_full` (snapshot/stream)
    - [x] `observability_gap.storage_disk_full` зарегистрировано в реестре с:
      - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/ops/storage.md`
  - [x] chaos: WAL corruption
    - [x] воспроизводимый способ порчи WAL описан
    - [x] отрабатывает алгоритм шага 1 (503+retry_after_ms + события + restore + integrity check)
  - [x] **Проверка (pass/fail):** существует `docs/ops/storage.md` (или отдельный документ) с точными шагами воспроизведения каждого сценария и критериями pass/fail; минимум smoke chaos прогоняется в CI.

## Документация (RU)
- [x] docs/core/storage.md
- [x] docs/ops/backup_restore_sqlite.md
- [x] docs/ops/storage_corruption_runbook.md
- [x] docs/ops/vacuum_schedule.md
- [x] docs/ops/storage.md

## Тестирование
- [x] integration: concurrency (шаг 3)
- [x] chaos: kill -9 (шаг 5)
- [x] chaos: disk full (шаг 5)
- [x] chaos: WAL corruption (шаг 5)

## CI gate
- [x] CI job `storage-integration` существует и запускает concurrency тест; job зелёный
- [x] CI job `storage-chaos-smoke` существует и запускает минимум 1 smoke прогон chaos сценариев; job зелёный
- [x] CI job `stage11-docs-gate` существует и запускает `scripts/ci/check_storage_stage11_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/ops/storage_corruption_runbook.md` содержит `HTTP 503` и `retry_after_ms` и `read_only`
    - [x] `docs/ops/vacuum_schedule.md` содержит `Sunday` или `воскресенье` и `03:30`
    - [x] `docs/ops/backup_restore_sqlite.md` содержит `integrity check`
  - [x] exit 1 при нарушении

## DoD
- [x] Recovery по corruption детерминирован и задокументирован; события `observability_gap.*` зарегистрированы и имеют runbook.
- [x] Backup/restore политика определена и выполнима.
- [x] Concurrency тест зелёный в CI.
- [x] VACUUM timer/unit существуют и smoke проверены.
- [x] Chaos сценарии воспроизводимы и имеют pass/fail критерии; минимум smoke прогоняется в CI.
- [x] CI gate Stage 11 зелёный.
