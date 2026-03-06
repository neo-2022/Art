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

- [ ] **1. Сделать:** Реализовать export scripts “audit pack”: incidents + audit в CSV и JSON (фиксированный формат).
  - [ ] Скрипт экспорта имеет фиксированное имя: `scripts/export_audit_pack.sh`
  - [ ] Скрипт принимает параметры:
    - [ ] `--from` (ISO date-time)
    - [ ] `--to` (ISO date-time)
    - [ ] `--out_dir` (путь каталога)
  - [ ] Скрипт экспортирует фиксированный набор файлов:
    - [ ] `incidents.json`
    - [ ] `incidents.csv`
    - [ ] `audit.json`
    - [ ] `audit.csv`
    - [ ] `meta.json` (содержит build_id, effective_profile_id, export_window, generated_at)
    - [ ] `checksums.txt` (sha256 для каждого файла audit pack)
  - [ ] Формат CSV фиксирован:
    - [ ] delimiter = `,`
    - [ ] encoding = UTF-8
    - [ ] header row обязателен
  - [ ] Скрипт НЕ экспортирует raw bytes вложений; экспортирует только метаданные, если они присутствуют в audit/incident (одно фиксированное решение)
  - [ ] **Проверка (pass/fail):** integration тест `export-audit-pack` запускает `scripts/export_audit_pack.sh` на тестовых данных и проверяет:
    - [ ] 6 файлов созданы
    - [ ] CSV содержит header row
    - [ ] `checksums.txt` соответствует sha256 файлов
    - [ ] `meta.json` содержит build_id и effective_profile_id.

- [ ] **2. Сделать:** Зафиксировать immutable evidence policy: хранение evidence в raw_archive и защита от изменений.
  - [ ] Существует файл `docs/compliance/evidence_list.md`
  - [ ] `docs/compliance/evidence_list.md` содержит фиксированное правило:
    - [ ] evidence артефакты кладутся только в `raw_archive/`
    - [ ] записи evidence неизменяемы (append-only; запрещено update/delete)
    - [ ] любые новые доказательства добавляются только добавлением новых файлов/записей
  - [ ] В документе перечислен минимальный набор evidence для аудитора:
    - [ ] branch protection proof
    - [ ] CI logs (security/contract/regression)
    - [ ] audit export pack checksums
    - [ ] DR drill report
  - [ ] **Проверка (pass/fail):** `docs/compliance/evidence_list.md` содержит все пункты выше и явно упоминает `raw_archive/` и “append-only”.

- [ ] **3. Сделать:** Зафиксировать data destruction policy (вывод из эксплуатации) с детерминированной процедурой.
  - [ ] Существует файл `docs/compliance/data_destruction.md`
  - [ ] Процедура фиксирована и содержит шаги:
    - [ ] stop Core/Agent
    - [ ] экспорт audit pack за окно “вся история” (фиксированная команда)
    - [ ] уничтожение ключей шифрования (если используются) или hard delete storage (одно фиксированное решение: hard delete)
    - [ ] удаление storage файлов (db/wal/backups/raw_archive) по фиксированным путям
    - [ ] верификация уничтожения (проверка отсутствия файлов + integrity check невозможен)
  - [ ] Определён критерий pass/fail уничтожения
  - [ ] **Проверка (pass/fail):** `docs/compliance/data_destruction.md` существует и содержит процедуру + критерии pass/fail.

- [ ] **4. Сделать:** Реализовать `observability_gap.export_failed` при провале экспорта audit pack.
  - [ ] Событие генерируется при любой ошибке `scripts/export_audit_pack.sh`:
    - [ ] IO error (нет прав/нет места)
    - [ ] invalid time window
    - [ ] storage read error
  - [ ] Событие попадает в snapshot/stream (через startup backlog, если экспорт выполнялся вне Core; фиксированная доставка: persisted backlog + публикация при следующем старте Core)
  - [ ] evidence_min:
    - [ ] from/to
    - [ ] out_dir
    - [ ] error (строка)
    - [ ] trace_id
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/export_failed.md`
  - [ ] **Проверка (pass/fail):** induced test ломает экспорт (например, out_dir без прав) и проверяет:
    - [ ] ненулевой exit code скрипта
    - [ ] после следующего старта Core событие `observability_gap.export_failed` появляется в `/api/v1/snapshot`.

- [ ] **5. Сделать:** Зафиксировать control matrix (контролі → доказательства) как источник правды для аудитора.
  - [ ] Существует файл `docs/compliance/control_matrix.md`
  - [ ] Файл содержит таблицу:
    - [ ] control_id
    - [ ] описание
    - [ ] evidence_ref (путь в raw_archive/ или путь в docs/)
    - [ ] owner_role
    - [ ] review_frequency (число + единица)
  - [ ] Таблица содержит минимум контролі:
    - [ ] supply-chain signing (Stage 04/24)
    - [ ] audit append-only (Stage 15)
    - [ ] retention/DSR (Stage 02)
    - [ ] DR drill (Stage 23)
    - [ ] contracts/codegen diff-clean (Stage 08)
  - [ ] **Проверка (pass/fail):** файл существует и содержит все колонки и минимум-контролі из списка.

- [ ] **6. Сделать:** RU-дока audit trail: что именно является “audit trail” и как его выгружать/проверять.
  - [ ] Существует `docs/compliance/audit_trail.md`
  - [ ] Документ содержит:
    - [ ] определение audit trail (AuditEntry append-only)
    - [ ] указание, что PII/secret фильтруется pre-write (Stage 15)
    - [ ] как запускать `scripts/export_audit_pack.sh`
    - [ ] как проверять `checksums.txt`
  - [ ] **Проверка (pass/fail):** документ существует и содержит перечисленные пункты.

## Документация (RU)
- [ ] docs/compliance/control_matrix.md
- [ ] docs/compliance/evidence_list.md
- [ ] docs/compliance/audit_trail.md
- [ ] docs/compliance/data_destruction.md
- [ ] docs/runbooks/export_failed.md
- [ ] scripts/export_audit_pack.sh

## Тестирование
- [ ] integration: `export-audit-pack` (runtime export из `/api/v1/incidents` + `/api/v1/audit`, шаг 1)
- [ ] induced: export fail → `observability_gap.export_failed` (шаг 4)

## CI gate
- [ ] CI job `export-audit-pack` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage25-docs-gate` существует и запускается на PR в main
- [ ] `stage25-docs-gate` запускает `scripts/ci/check_compliance_stage25_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/compliance/evidence_list.md` содержит `raw_archive` и `append-only`
    - [ ] `docs/compliance/control_matrix.md` содержит `control_id` и `evidence_ref` и `review_frequency`
    - [ ] `docs/compliance/audit_trail.md` содержит `export_audit_pack.sh` и `checksums.txt`
    - [ ] `docs/compliance/data_destruction.md` содержит `stop` и `backup` (audit pack) и `pass/fail`
    - [ ] `docs/runbooks/export_failed.md` содержит `mitigations` и `verification`
    - [ ] `docs/governance/observability_gap_registry.md` содержит `export_failed`
    - [ ] `scripts/export_audit_pack.sh` содержит runtime fetch `/api/v1/incidents` и `/api/v1/audit`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Экспорт audit pack (incidents + audit) в CSV/JSON реализован, выдаёт checksums и meta, и подтверждён integration тестом.
- [ ] Immutable evidence policy зафиксирована: raw_archive + append-only.
- [ ] Data destruction policy зафиксирована и имеет критерии pass/fail.
- [ ] `observability_gap.export_failed` реализован, зарегистрирован и покрыт induced test (включая публикацию startup backlog).
- [ ] Control matrix и audit trail docs существуют и однозначны.
- [ ] CI gate Stage 25 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
