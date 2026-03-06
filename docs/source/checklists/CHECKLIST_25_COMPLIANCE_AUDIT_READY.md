A) Полный запрет опциональности:
# CHECKLIST 25 — Compliance/Audit readiness
Файл: CHECKLIST_25_COMPLIANCE_AUDIT_READY.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: требования аудитора; изменение форматов экспорта; изменение raw_archive; изменение retention/DSR; изменение audit policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Audit-ready однозначен и проверяем: export pack (incidents + audit) в CSV/JSON; immutable evidence policy (raw_archive + защита от изменений); data destruction policy (вывод из эксплуатации); `observability_gap.export_failed` при сбое экспорта; CI gate проверяет содержимое документов (не только наличие).

## Границы
Только тех. доказательная база и процедуры для аудитора:
- экспорт “audit pack”
- список контролей/доказательств (control matrix + evidence list)
- политика неизменяемых доказательств (raw_archive)
- политика уничтожения данных (decommission)
- наблюдаемость провала экспорта

## Зависимости
- CHECKLIST 24 — Release/Upgrade/Regression
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 03 — Regional profiles
- CHECKLIST 04 — Secure SDLC + Supply-chain
- CHECKLIST 15 — Actions/Audit/RBAC/PII (audit append-only, pre-write redaction)

## Шаги (строго линейно)

- [x] **1. Сделать:** Реализовать export scripts “audit pack”: incidents + audit в CSV и JSON (фиксированный формат).
  - [x] Скрипт экспорта имеет фиксированное имя: `scripts/export_audit_pack.sh`
  - [x] Скрипт принимает параметры:
    - [x] `--from` (ISO date-time)
    - [x] `--to` (ISO date-time)
    - [x] `--out_dir` (путь каталога)
  - [x] Скрипт экспортирует фиксированный набор файлов:
    - [x] `incidents.json`
    - [x] `incidents.csv`
    - [x] `audit.json`
    - [x] `audit.csv`
    - [x] `meta.json` (содержит build_id, effective_profile_id, export_window, generated_at)
    - [x] `checksums.txt` (sha256 для каждого файла audit pack)
  - [x] Формат CSV фиксирован:
    - [x] delimiter = `,`
    - [x] encoding = UTF-8
    - [x] header row обязателен
  - [x] Скрипт НЕ экспортирует raw bytes вложений; экспортирует только метаданные, если они присутствуют в audit/incident (одно фиксированное решение)
  - [x] **Проверка (pass/fail):** integration тест `export-audit-pack` запускает `scripts/export_audit_pack.sh` на тестовых данных и проверяет:
    - [x] 6 файлов созданы
    - [x] CSV содержит header row
    - [x] `checksums.txt` соответствует sha256 файлов
    - [x] `meta.json` содержит build_id и effective_profile_id.

- [x] **2. Сделать:** Зафиксировать immutable evidence policy: хранение evidence в raw_archive и защита от изменений.
  - [x] Существует файл `docs/compliance/evidence_list.md`
  - [x] `docs/compliance/evidence_list.md` содержит фиксированное правило:
    - [x] evidence артефакты кладутся только в `raw_archive/`
    - [x] записи evidence неизменяемы (append-only; запрещено update/delete)
    - [x] любые новые доказательства добавляются только добавлением новых файлов/записей
  - [x] В документе перечислен минимальный набор evidence для аудитора:
    - [x] branch protection proof
    - [x] CI logs (security/contract/regression)
    - [x] audit export pack checksums
    - [x] DR drill report
  - [x] **Проверка (pass/fail):** `docs/compliance/evidence_list.md` содержит все пункты выше и явно упоминает `raw_archive/` и “append-only”.

- [x] **3. Сделать:** Зафиксировать data destruction policy (вывод из эксплуатации) с детерминированной процедурой.
  - [x] Существует файл `docs/compliance/data_destruction.md`
  - [x] Процедура фиксирована и содержит шаги:
    - [x] stop Core/Agent
    - [x] экспорт audit pack за окно “вся история” (фиксированная команда)
    - [x] уничтожение ключей шифрования (если используются) или hard delete storage (одно фиксированное решение: hard delete)
    - [x] удаление storage файлов (db/wal/backups/raw_archive) по фиксированным путям
    - [x] верификация уничтожения (проверка отсутствия файлов + integrity check невозможен)
  - [x] Определён критерий pass/fail уничтожения
  - [x] **Проверка (pass/fail):** `docs/compliance/data_destruction.md` существует и содержит процедуру + критерии pass/fail.

- [x] **4. Сделать:** Реализовать `observability_gap.export_failed` при провале экспорта audit pack.
  - [x] Событие генерируется при любой ошибке `scripts/export_audit_pack.sh`:
    - [x] IO error (нет прав/нет места)
    - [x] invalid time window
    - [x] storage read error
  - [x] Событие попадает в snapshot/stream (через startup backlog, если экспорт выполнялся вне Core; фиксированная доставка: persisted backlog + публикация при следующем старте Core)
  - [x] evidence_min:
    - [x] from/to
    - [x] out_dir
    - [x] error (строка)
    - [x] trace_id
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/export_failed.md`
  - [x] **Проверка (pass/fail):** induced test ломает экспорт (например, out_dir без прав) и проверяет:
    - [x] ненулевой exit code скрипта
    - [x] после следующего старта Core событие `observability_gap.export_failed` появляется в `/api/v1/snapshot`.

- [x] **5. Сделать:** Зафиксировать control matrix (контролі → доказательства) как источник правды для аудитора.
  - [x] Существует файл `docs/compliance/control_matrix.md`
  - [x] Файл содержит таблицу:
    - [x] control_id
    - [x] описание
    - [x] evidence_ref (путь в raw_archive/ или путь в docs/)
    - [x] owner_role
    - [x] review_frequency (число + единица)
  - [x] Таблица содержит минимум контролі:
    - [x] supply-chain signing (Stage 04/24)
    - [x] audit append-only (Stage 15)
    - [x] retention/DSR (Stage 02)
    - [x] DR drill (Stage 23)
    - [x] contracts/codegen diff-clean (Stage 08)
  - [x] **Проверка (pass/fail):** файл существует и содержит все колонки и минимум-контролі из списка.

- [x] **6. Сделать:** RU-дока audit trail: что именно является “audit trail” и как его выгружать/проверять.
  - [x] Существует `docs/compliance/audit_trail.md`
  - [x] Документ содержит:
    - [x] определение audit trail (AuditEntry append-only)
    - [x] указание, что PII/secret фильтруется pre-write (Stage 15)
    - [x] как запускать `scripts/export_audit_pack.sh`
    - [x] как проверять `checksums.txt`
  - [x] **Проверка (pass/fail):** документ существует и содержит перечисленные пункты.

## Документация (RU)
- [x] docs/compliance/control_matrix.md
- [x] docs/compliance/evidence_list.md
- [x] docs/compliance/audit_trail.md
- [x] docs/compliance/data_destruction.md
- [x] docs/runbooks/export_failed.md
- [x] scripts/export_audit_pack.sh

## Тестирование
- [x] integration: `export-audit-pack` (runtime export из `/api/v1/incidents` + `/api/v1/audit`, шаг 1)
- [x] induced: export fail → `observability_gap.export_failed` (шаг 4)

## CI gate
- [x] CI job `export-audit-pack` существует и запускается на PR в main; job зелёный
- [x] CI job `stage25-docs-gate` существует и запускается на PR в main
- [x] `stage25-docs-gate` запускает `scripts/ci/check_compliance_stage25_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/compliance/evidence_list.md` содержит `raw_archive` и `append-only`
    - [x] `docs/compliance/control_matrix.md` содержит `control_id` и `evidence_ref` и `review_frequency`
    - [x] `docs/compliance/audit_trail.md` содержит `export_audit_pack.sh` и `checksums.txt`
    - [x] `docs/compliance/data_destruction.md` содержит `stop` и `backup` (audit pack) и `pass/fail`
    - [x] `docs/runbooks/export_failed.md` содержит `mitigations` и `verification`
    - [x] `docs/governance/observability_gap_registry.md` содержит `export_failed`
    - [x] `scripts/export_audit_pack.sh` содержит runtime fetch `/api/v1/incidents` и `/api/v1/audit`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Экспорт audit pack (incidents + audit) в CSV/JSON реализован, выдаёт checksums и meta, и подтверждён integration тестом.
- [x] Immutable evidence policy зафиксирована: raw_archive + append-only.
- [x] Data destruction policy зафиксирована и имеет критерии pass/fail.
- [x] `observability_gap.export_failed` реализован, зарегистрирован и покрыт induced test (включая публикацию startup backlog).
- [x] Control matrix и audit trail docs существуют и однозначны.
- [x] CI gate Stage 25 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
