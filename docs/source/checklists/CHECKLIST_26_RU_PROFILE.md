A) Полный запрет опциональности:
# CHECKLIST 26 — РФ профиль (152-ФЗ/локализация/экспорт/аудит доступа/air-gapped)
Файл: CHECKLIST_26_RU_PROFILE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение PDn списка; изменение export policy; изменение требований локализации; изменение audit schema; изменение airgapped/packs policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
RU профиль однозначен и проверяем: фиксированный список ПДн (field paths), аудит доступа к PII-инцидентам (append-only), блокировка трансграничного экспорта, airgapped install/update (включая packs), и gap событие `observability_gap.cross_border_export_blocked` с runbook.

## Границы
Тех. профиль RU и проверки (policy + enforcement + тесты + docs).  
Не включает юридическую интерпретацию 152-ФЗ — только технические требования и артефакты.

## Зависимости
- CHECKLIST 03 — Regional profiles (profile guards, data residency)
- CHECKLIST 25 — Compliance/Audit readiness (export audit pack, evidence)
- CHECKLIST 15 — Actions/Audit/RBAC/PII (audit append-only + pre-write redaction)

## Шаги (строго линейно)

- [ ] **1. Сделать:** Определить фиксированный список ПДн полей (field paths) для RU профиля и зафиксировать правила обработки.
  - [ ] Список ПДн оформлен как перечень `field_path` (dotted path) и покрывает минимум:
    - [ ] `message` (если содержит PII)
    - [ ] `ctx.*` (все поля контекста, в которых допускается PII)
    - [ ] `payload.*` (все поля payload, в которых допускается PII)
    - [ ] `audit.client_ip` (как PII, даже в нормализованном виде)
    - [ ] `audit.user_agent` (как потенциальное PII)
  - [ ] Для каждого `field_path` указано фиксированное правило обработки: `store_ru_only` | `redact_on_export` | `drop`
  - [ ] Запрещены ссылки вида “как в global”; правила должны быть конкретными для RU
  - [ ] **Проверка (pass/fail):** существует `docs/ru/profile_ru.md`, содержит список `field_path` + правило обработки для каждого пункта.

- [ ] **2. Сделать:** Реализовать audit доступа к PII-инцидентам: каждый просмотр инцидента с PII фиксируется в append-only журнале.
  - [ ] “Просмотр” фиксируется при любом успешном доступе к PII-инциденту через API:
    - [ ] `GET /api/v1/incidents/{id}` (единственный способ чтения инцидента)
  - [ ] Audit запись содержит фиксированный минимум полей:
    - [ ] `timestamp`
    - [ ] `actor_id`
    - [ ] `actor_role`
    - [ ] `incident_id`
    - [ ] `client_ip` (в нормализованном виде по Stage 15)
    - [ ] `user_agent` (max 256 после фильтрации по Stage 15)
    - [ ] `trace_id`
  - [ ] Audit журнал append-only (update/delete запрещены), покрыт immutability test (фиксированное решение: отдельный RU integration test)
  - [ ] **Проверка (pass/fail):** существует `docs/ru/access_audit.md` и integration test `ru-access-audit`:
    - [ ] выполняет просмотр PII-инцидента через `GET /api/v1/incidents/{id}`
    - [ ] проверяет наличие audit записи с полями выше
    - [ ] проверяет append-only (update/delete fail).

- [ ] **3. Сделать:** Реализовать блокировку трансграничного экспорта в RU профиле (fail closed).
  - [ ] Определение “экспорт” фиксировано: любой запуск `scripts/export_audit_pack.sh` и любой API/Action, выполняющий выгрузку данных из системы наружу
  - [ ] При `effective_profile_id=ru` экспорт разрешён только в `out_dir`, который находится на локальном файловом пути РФ-инсталляции (одно фиксированное тех. правило):
    - [ ] запрет сетевых путей/URL (например `s3://`, `http://`, `https://`, `scp://`) — блокируется всегда
    - [ ] запрет путей вне allowlist директории (allowlist фиксирован в конфиге RU профиля, один путь)
  - [ ] При нарушении экспорт блокируется (команда/endpoint завершается ошибкой) и генерируется событие из шага 5
  - [ ] **Проверка (pass/fail):** integration test `ru-export-blocked`:
    - [ ] включает RU профиль
    - [ ] пытается выполнить экспорт в запрещённый “внешний” target
    - [ ] подтверждает отказ экспорта.

- [ ] **4. Сделать:** Airgapped установка и обновления RU профиля (включая packs): процедура однозначна.
  - [ ] RU профиль требует airgapped режима: updates и packs устанавливаются только из локального файла
  - [ ] Процедура включает фиксированные шаги:
    - [ ] доставка пакета обновления на машину
    - [ ] проверка подписи (cosign verify)
    - [ ] проверка checksums
    - [ ] установка
    - [ ] smoke-check
  - [ ] **Проверка (pass/fail):** существует `docs/ru/airgapped_install.md`, содержит шаги выше в указанном порядке и точные команды.

- [ ] **5. Сделать:** Реализовать `observability_gap.cross_border_export_blocked` при попытке запрещённого экспорта (RU профиль).
  - [ ] Событие генерируется при каждом блокировании экспорта по правилам шага 3
  - [ ] Событие попадает в snapshot/stream (через startup backlog, если экспорт выполнялся вне Core; фиксированная доставка: persisted backlog + публикация при следующем старте Core)
  - [ ] evidence_min:
    - [ ] `effective_profile_id=ru`
    - [ ] export_target (строка)
    - [ ] rule_id (строка)
    - [ ] actor_id (если известен)
    - [ ] trace_id
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/cross_border_export_blocked.md`
  - [ ] **Проверка (pass/fail):** induced test:
    - [ ] запускает экспорт в запрещённый target при RU профиле
    - [ ] подтверждает отказ экспорта
    - [ ] подтверждает появление `observability_gap.cross_border_export_blocked` в `/api/v1/snapshot`.

## Документация (RU)
- [ ] docs/ru/profile_ru.md
- [ ] docs/ru/access_audit.md
- [ ] docs/ru/export.md
- [ ] docs/ru/airgapped_install.md
- [ ] docs/runbooks/cross_border_export_blocked.md

## Тестирование
- [ ] integration: `ru-export-blocked` (шаг 3, проверка server-side effective_profile_id из Core)
- [ ] integration: `ru-access-audit` (шаг 2)
- [ ] induced: cross-border export blocked → gap event (шаг 5)

## CI gate
- [ ] CI job `ru-profile-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage26-docs-gate` существует и запускается на PR в main
- [ ] `stage26-docs-gate` запускает `scripts/ci/check_ru_profile_stage26_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/ru/profile_ru.md` содержит `field_path` и `store_ru_only`
    - [ ] `docs/ru/access_audit.md` содержит `GET /api/v1/incidents/{id}` и `incident_id` и `client_ip` и `user_agent`
    - [ ] `docs/ru/export.md` содержит `effective_profile_id=ru` и `blocked`
    - [ ] `docs/ru/airgapped_install.md` содержит `cosign` и `verify` и `checksums`
    - [ ] `docs/runbooks/cross_border_export_blocked.md` содержит `mitigations` и `verification`
    - [ ] `docs/governance/observability_gap_registry.md` содержит `cross_border_export_blocked`
    - [ ] `scripts/export_audit_pack.sh` содержит server-side policy check по `effective_profile_id` и `RU_EXPORT_ALLOWLIST_ROOT`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Список ПДн полей (field paths) RU профиля определён и задокументирован без ссылок на другие профили.
- [ ] Audit доступа к PII-инцидентам реализован (append-only) и подтверждён integration test.
- [ ] Трансграничный экспорт заблокирован в RU профиле (fail closed) и подтверждён integration test (env override не обходит server-side policy).
- [ ] Airgapped install/update RU профиля (включая packs) задокументирован с точными командами.
- [ ] `observability_gap.cross_border_export_blocked` реализован, зарегистрирован и покрыт induced test.
- [ ] CI gate Stage 26 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
