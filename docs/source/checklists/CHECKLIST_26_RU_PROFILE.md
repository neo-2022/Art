A) Полный запрет опциональности:
# CHECKLIST 26 — РФ профиль (152-ФЗ/локализация/экспорт/аудит доступа/air-gapped)
Файл: CHECKLIST_26_RU_PROFILE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение PDn списка; изменение export policy; изменение требований локализации; изменение audit schema; изменение airgapped/packs policy

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

- [x] **1. Сделать:** Определить фиксированный список ПДн полей (field paths) для RU профиля и зафиксировать правила обработки.
  - [x] Список ПДн оформлен как перечень `field_path` (dotted path) и покрывает минимум:
    - [x] `message` (если содержит PII)
    - [x] `ctx.*` (все поля контекста, в которых допускается PII)
    - [x] `payload.*` (все поля payload, в которых допускается PII)
    - [x] `audit.client_ip` (как PII, даже в нормализованном виде)
    - [x] `audit.user_agent` (как потенциальное PII)
  - [x] Для каждого `field_path` указано фиксированное правило обработки: `store_ru_only` | `redact_on_export` | `drop`
  - [x] Запрещены ссылки вида “как в global”; правила должны быть конкретными для RU
  - [x] **Проверка (pass/fail):** существует `docs/ru/profile_ru.md`, содержит список `field_path` + правило обработки для каждого пункта.

- [x] **2. Сделать:** Реализовать audit доступа к PII-инцидентам: каждый просмотр инцидента с PII фиксируется в append-only журнале.
  - [x] “Просмотр” фиксируется при любом успешном доступе к PII-инциденту через API:
    - [x] `GET /api/v1/incidents/{id}` (единственный способ чтения инцидента)
  - [x] Audit запись содержит фиксированный минимум полей:
    - [x] `timestamp`
    - [x] `actor_id`
    - [x] `actor_role`
    - [x] `incident_id`
    - [x] `client_ip` (в нормализованном виде по Stage 15)
    - [x] `user_agent` (max 256 после фильтрации по Stage 15)
    - [x] `trace_id`
  - [x] Audit журнал append-only (update/delete запрещены), покрыт immutability test (фиксированное решение: отдельный RU integration test)
  - [x] **Проверка (pass/fail):** существует `docs/ru/access_audit.md` и integration test `ru-access-audit`:
    - [x] выполняет просмотр PII-инцидента через `GET /api/v1/incidents/{id}`
    - [x] проверяет наличие audit записи с полями выше
    - [x] проверяет append-only (update/delete fail).

- [x] **3. Сделать:** Реализовать блокировку трансграничного экспорта в RU профиле (fail closed).
  - [x] Определение “экспорт” фиксировано: любой запуск `scripts/export_audit_pack.sh` и любой API/Action, выполняющий выгрузку данных из системы наружу
  - [x] При `effective_profile_id=ru` экспорт разрешён только в `out_dir`, который находится на локальном файловом пути РФ-инсталляции (одно фиксированное тех. правило):
    - [x] запрет сетевых путей/URL (например `s3://`, `http://`, `https://`, `scp://`) — блокируется всегда
    - [x] запрет путей вне allowlist директории (allowlist фиксирован в конфиге RU профиля, один путь)
  - [x] При нарушении экспорт блокируется (команда/endpoint завершается ошибкой) и генерируется событие из шага 5
  - [x] **Проверка (pass/fail):** integration test `ru-export-blocked`:
    - [x] включает RU профиль
    - [x] пытается выполнить экспорт в запрещённый “внешний” target
    - [x] подтверждает отказ экспорта.

- [x] **4. Сделать:** Airgapped установка и обновления RU профиля (включая packs): процедура однозначна.
  - [x] RU профиль требует airgapped режима: updates и packs устанавливаются только из локального файла
  - [x] Процедура включает фиксированные шаги:
    - [x] доставка пакета обновления на машину
    - [x] проверка подписи (cosign verify)
    - [x] проверка checksums
    - [x] установка
    - [x] smoke-check
  - [x] **Проверка (pass/fail):** существует `docs/ru/airgapped_install.md`, содержит шаги выше в указанном порядке и точные команды.

- [x] **5. Сделать:** Реализовать `observability_gap.cross_border_export_blocked` при попытке запрещённого экспорта (RU профиль).
  - [x] Событие генерируется при каждом блокировании экспорта по правилам шага 3
  - [x] Событие попадает в snapshot/stream (через startup backlog, если экспорт выполнялся вне Core; фиксированная доставка: persisted backlog + публикация при следующем старте Core)
  - [x] evidence_min:
    - [x] `effective_profile_id=ru`
    - [x] export_target (строка)
    - [x] rule_id (строка)
    - [x] actor_id (если известен)
    - [x] trace_id
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/cross_border_export_blocked.md`
  - [x] **Проверка (pass/fail):** induced test:
    - [x] запускает экспорт в запрещённый target при RU профиле
    - [x] подтверждает отказ экспорта
    - [x] подтверждает появление `observability_gap.cross_border_export_blocked` в `/api/v1/snapshot`.

## Документация (RU)
- [x] docs/ru/profile_ru.md
- [x] docs/ru/access_audit.md
- [x] docs/ru/export.md
- [x] docs/ru/airgapped_install.md
- [x] docs/runbooks/cross_border_export_blocked.md

## Тестирование
- [x] integration: `ru-export-blocked` (шаг 3, проверка server-side effective_profile_id из Core)
- [x] integration: `ru-access-audit` (шаг 2)
- [x] induced: cross-border export blocked → gap event (шаг 5)

## CI gate
- [x] CI job `ru-profile-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `stage26-docs-gate` существует и запускается на PR в main
- [x] `stage26-docs-gate` запускает `scripts/ci/check_ru_profile_stage26_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/ru/profile_ru.md` содержит `field_path` и `store_ru_only`
    - [x] `docs/ru/access_audit.md` содержит `GET /api/v1/incidents/{id}` и `incident_id` и `client_ip` и `user_agent`
    - [x] `docs/ru/export.md` содержит `effective_profile_id=ru` и `blocked`
    - [x] `docs/ru/airgapped_install.md` содержит `cosign` и `verify` и `checksums`
    - [x] `docs/runbooks/cross_border_export_blocked.md` содержит `mitigations` и `verification`
    - [x] `docs/governance/observability_gap_registry.md` содержит `cross_border_export_blocked`
    - [x] `scripts/export_audit_pack.sh` содержит server-side policy check по `effective_profile_id` и `RU_EXPORT_ALLOWLIST_ROOT`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Список ПДн полей (field paths) RU профиля определён и задокументирован без ссылок на другие профили.
- [x] Audit доступа к PII-инцидентам реализован (append-only) и подтверждён integration test.
- [x] Трансграничный экспорт заблокирован в RU профиле (fail closed) и подтверждён integration test (env override не обходит server-side policy).
- [x] Airgapped install/update RU профиля (включая packs) задокументирован с точными командами.
- [x] `observability_gap.cross_border_export_blocked` реализован, зарегистрирован и покрыт induced test.
- [x] CI gate Stage 26 зелёный.
