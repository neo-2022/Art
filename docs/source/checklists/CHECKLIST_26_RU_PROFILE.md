A) Полный запрет опциональности:
# CHECKLIST 26 — РФ профиль (152-ФЗ/1119/17/21/239, локализация, экспорт, аудит доступа, air-gapped)
Файл: CHECKLIST_26_RU_PROFILE.md  
Последняя актуализация: 2026-03-06  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение PDn списка; изменение export policy; изменение требований локализации; изменение audit schema; изменение airgapped/packs policy; изменение нормативных требований РФ/ФСТЭК; изменение перечня обязательных РФ-ОС
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
RU профиль однозначен и проверяем: machine-readable нормативный контур РФ, фиксированный список ПДн (field paths), аудит доступа к PII-инцидентам (append-only), блокировка трансграничного экспорта, airgapped install/update (включая packs), certified-ready/FSTEC-like профиль без ложного claim о сертификации, и gap событие `observability_gap.cross_border_export_blocked` с runbook.

## Границы
Тех. профиль RU и проверки (policy + enforcement + тесты + docs).  
Не включает юридическую интерпретацию законодательства — только технические требования, артефакты и контуры соответствия.

## Зависимости
- CHECKLIST 03 — Regional profiles (profile guards, data residency)
- CHECKLIST 25 — Compliance/Audit readiness (export audit pack, evidence)
- CHECKLIST 15 — Actions/Audit/RBAC/PII (audit append-only + pre-write redaction)
- CHECKLIST 37 — Linux production hardening (platform matrix, certified profile, RF distros)

## Шаги (строго линейно)

- [ ] **0. Сделать:** Зафиксировать machine-readable нормативный контур РФ как source-of-truth.
  - [ ] существует `formats/ru_regulatory_scope.yaml`
  - [ ] файл фиксирует минимум scopes:
    - [ ] `PDN`
    - [ ] `GIS`
    - [ ] `KII`
    - [ ] `SZI_TRUST`
  - [ ] файл фиксирует минимум нормативные anchors:
    - [ ] `152-ФЗ`
    - [ ] `ПП РФ №1119`
    - [ ] `ФСТЭК Приказ №21`
    - [ ] `ФСТЭК Приказ №17`
    - [ ] `187-ФЗ`
    - [ ] `ФСТЭК Приказ №239`
  - [ ] файл фиксирует обязательные РФ-дистрибутивы:
    - [ ] `Astra Linux Special Edition`
    - [ ] `RED OS`
    - [ ] `ALT Linux`
    - [ ] `ROSA Linux`
  - [ ] файл явно различает:
    - [ ] `certified_ready`
    - [ ] `certified`
  - [ ] запрещено заявлять `сертифицировано`, пока сертификация реально не пройдена
  - [ ] **Проверка (pass/fail):** YAML существует, валиден и docs/CI ссылаются на него как на source-of-truth RU профиля.

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
  - [ ] При нарушении экспорт блокируется (команда/endpoint завершается ошибкой) и генерируется событие из шага 6
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

- [ ] **5. Сделать:** Зафиксировать certified-ready/FSTEC-like профиль RU контура без ложных заявлений о сертификации.
  - [ ] `docs/security/fstec-certified-profile.md` и `docs/ru/profile_ru.md` явно различают `certified_ready` и `certified`
  - [ ] RU профиль использует `formats/platform_support.yaml` и `formats/ru_regulatory_scope.yaml` как два обязательных source-of-truth
  - [ ] для профиля фиксируются минимум ограничения:
    - [ ] no dynamic loading
    - [ ] dependency allowlist
    - [ ] reproducible build flags
    - [ ] signed release hook
    - [ ] airgapped install/update
  - [ ] **Проверка (pass/fail):** документы содержат все ограничения и не используют ложную формулировку `сертифицировано`.

- [ ] **5A. Сделать:** Зафиксировать обязательную поддержку РФ-ОС для RU/gov контура как часть профиля, а не как внешний комментарий.
  - [ ] `docs/ru/profile_ru.md` и `docs/ops/platform-support.md` явно связывают RU профиль с:
    - [ ] `Astra Linux SE`
    - [ ] `RED OS`
    - [ ] `ALT Linux`
    - [ ] `ROSA Linux`
  - [ ] для этих дистрибутивов зафиксировано:
    - [ ] install method
    - [ ] natural test status
    - [ ] evidence placeholder id
  - [ ] **Проверка (pass/fail):** docs/gates подтверждают наличие всех четырёх РФ-дистрибутивов и их статусов.

- [ ] **6. Сделать:** Реализовать `observability_gap.cross_border_export_blocked` при попытке запрещённого экспорта (RU профиль).
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
- [ ] formats/ru_regulatory_scope.yaml
- [ ] docs/ru/profile_ru.md
- [ ] docs/ru/access_audit.md
- [ ] docs/ru/export.md
- [ ] docs/ru/airgapped_install.md
- [ ] docs/security/fstec-certified-profile.md
- [ ] docs/runbooks/cross_border_export_blocked.md

## Тестирование
- [ ] integration: `ru-export-blocked` (шаг 3, проверка server-side effective_profile_id из Core)
- [ ] integration: `ru-access-audit` (шаг 2)
- [ ] induced: cross-border export blocked → gap event (шаг 6)

## CI gate
- [ ] CI job `ru-profile-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage26-docs-gate` существует и запускается на PR в main
- [ ] `stage26-docs-gate` запускает `scripts/ci/check_ru_profile_stage26_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `formats/ru_regulatory_scope.yaml` содержит `PDN`, `GIS`, `KII`, `SZI_TRUST`, `152-ФЗ`, `1119`, `21`, `17`, `187-ФЗ`, `239`, `Astra`, `RED`, `ALT`, `ROSA`
    - [ ] `docs/ru/profile_ru.md` содержит `field_path` и `store_ru_only`
    - [ ] `docs/ru/access_audit.md` содержит `GET /api/v1/incidents/{id}` и `incident_id` и `client_ip` и `user_agent`
    - [ ] `docs/ru/export.md` содержит `effective_profile_id=ru` и `blocked`
    - [ ] `docs/ru/airgapped_install.md` содержит `cosign` и `verify` и `checksums`
    - [ ] `docs/security/fstec-certified-profile.md` содержит `certified_ready` и не содержит ложного production claim о пройденной сертификации
    - [ ] `docs/runbooks/cross_border_export_blocked.md` содержит `mitigations` и `verification`
    - [ ] `docs/governance/observability_gap_registry.md` содержит `cross_border_export_blocked`
    - [ ] `scripts/export_audit_pack.sh` содержит server-side policy check по `effective_profile_id` и `RU_EXPORT_ALLOWLIST_ROOT`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Machine-readable нормативный контур РФ зафиксирован в `formats/ru_regulatory_scope.yaml` и используется как source-of-truth.
- [ ] Список ПДн полей (field paths) RU профиля определён и задокументирован без ссылок на другие профили.
- [ ] Audit доступа к PII-инцидентам реализован (append-only) и подтверждён integration test.
- [ ] Трансграничный экспорт заблокирован в RU профиле (fail closed) и подтверждён integration test (env override не обходит server-side policy).
- [ ] Airgapped install/update RU профиля (включая packs) задокументирован с точными командами.
- [ ] Certified-ready/FSTEC-like профиль зафиксирован без ложного claim о сертификации.
- [ ] Обязательная поддержка РФ-ОС (`Astra/RED/ALT/ROSA`) встроена в RU профиль и связана с platform matrix/evidence.
- [ ] `observability_gap.cross_border_export_blocked` реализован, зарегистрирован и покрыт induced test.
- [ ] CI gate Stage 26 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
