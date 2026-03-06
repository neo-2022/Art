A) Полный запрет опциональности:
# CHECKLIST 02 — Privacy baseline (global)
Файл: CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение схем RawEvent/Incident/Audit/attachments; изменение redaction rules; изменение retention; изменение региональных профилей
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Зафиксировать privacy-by-design: классификация данных, PII surface, redaction с событием `privacy.redaction_applied`, политика “no HTTP bodies by default”, retention, DSR, политика вложений (включая потенциальную PII в attachments), и управляемые failure-моды через `observability_gap.*`.

## Границы
Технические политики и требования к реализации (документы, схемы/поля, тесты и CI gate).  
Процессы governance/incident/severity/audit enforce-уровня описаны в Stage 01, здесь — privacy baseline и его enforce.

## Зависимости
- CHECKLIST_01_GOVERNANCE_SRE.md (severity, incident rules, реестр `observability_gap.*`, runbook policy, audit policy)

## Шаги (строго линейно)

1. [x] **Сделать:** Зафиксировать классификацию данных и примеры для проекта (PII, secrets, telemetry, operational, attachments).  
   **Проверка (pass/fail):** существует `docs/privacy/data_classification.md`, содержит:
   - категории данных и определения
   - список примеров PII (email, IP, username, external ids и т.д.)
   - список примеров secrets (keys, tokens, cookies, auth headers)
   - отдельный раздел “Attachments как потенциальная PII”

2. [x] **Сделать:** Определить PII surface (полевая карта) для всех записываемых сущностей: RawEvent, Incident, AuditEntry, AttachmentMeta.  
   **Проверка (pass/fail):** в `docs/privacy/pii_surface.md` есть таблица/список `field_paths`, и для каждой сущности указан:
   - `field_path`
   - категория (PII/secrets/telemetry/operational)
   - правило обработки (store/redact/drop)
   - владелец (owner_component)

3. [x] **Сделать:** Зафиксировать политику минимизации данных: “no HTTP bodies by default”, запрет записи произвольных headers/cookies, allowlist полей контекста.  
   **Проверка (pass/fail):** существует `docs/privacy/data_minimization_policy.md`, содержит:
   - явное правило “no HTTP bodies by default”
   - явный allowlist записываемых HTTP-полей (если есть) и запрет по умолчанию для остального
   - правила для message/payload/context: что разрешено, что дропается

4. [x] **Сделать:** Зафиксировать redaction policy для PII/secrets (маскирование/удаление) по `field_paths` + детерминированные `rule_id`.  
   **Проверка (pass/fail):** существует `docs/privacy/redaction_policy.md`, содержит:
   - источники, где применяется redaction (message/payload/context/attachments meta/audit pre-write)
   - идентификаторы правил `rule_id` и область действия (field paths)
   - требования: redaction применяется ДО записи в AuditEntry и ДО выдачи наружу (UI/API)

5. [x] **Сделать:** Зафиксировать требование: redaction rules изменяются конфигом без перекомпиляции/релиза кода (смена правил = смена конфигурации).  
   **Проверка (pass/fail):** `docs/privacy/redaction_policy.md` содержит раздел `configurable rules`, в котором указано:
   - где хранится конфиг rules
   - как версионируются rules
   - как происходит rollout/rollback rules

6. [x] **Сделать:** Зафиксировать обязательное событие `privacy.redaction_applied` при любом факте применения redaction.  
   **Проверка (pass/fail):** `docs/privacy/redaction_policy.md` содержит раздел `privacy.redaction_applied`, в котором определено минимальное содержимое события:
   - `timestamp`
   - `rule_id`
   - `field_paths` (список путей)
   - `redaction_count`
   - `owner_component`
   и явное правило: событие пишется всегда, если redaction реально изменила данные.

7. [x] **Сделать:** Зафиксировать failure-мод redaction: при невозможности применить redaction генерируется `observability_gap.redaction_failed`, и это событие обязано попасть в snapshot/stream.  
   **Проверка (pass/fail):** `docs/privacy/redaction_policy.md` содержит раздел `observability_gap.redaction_failed`, где указано:
   - условия генерации (сломанный конфиг, исключение фильтра, неизвестная схема)
   - обязательные поля evidence_min (ошибка/контекст/счётчики)
   - требование зарегистрировать событие в `docs/governance/observability_gap_registry.md` (Stage 01) с `incident_rule` и `action_ref`

8. [x] **Сделать:** Зафиксировать retention matrix для: events, incidents, audit, attachments, raw archive (если существует).  
   **Проверка (pass/fail):** существует `docs/privacy/retention_matrix.md`, содержит таблицу:
   - тип данных
   - срок хранения (число + единица)
   - место хранения
   - метод удаления (hard delete / crypto-shred — выбрать и зафиксировать один для каждого типа)
   - ответственный компонент (owner_component)

9. [x] **Сделать:** Зафиксировать DSR процесс: export/delete/rectify и правило “audit append-only; PII редактируется ДО записи в audit”.  
   **Проверка (pass/fail):** существует `docs/privacy/dsr_process.md`, содержит:
   - шаги export/delete/rectify
   - правило идентификации субъекта запроса (какие идентификаторы принимаются)
   - правило: AuditEntry не редактируется задним числом; PII/Secrets должны быть redacted pre-write
   - ссылки на retention matrix и audit policy

10. [x] **Сделать:** Зафиксировать policy вложений (attachments): MIME allowlist, magic bytes проверка, max size, sanitize filename, запрет XSS (в т.ч. SVG/HTML), отдельная retention для потенциально PII-вложений.  
    **Проверка (pass/fail):** существует `docs/privacy/attachments_security.md`, содержит:
    - allowlist MIME
    - требование проверки magic bytes
    - max size (число + единица) и поведение при превышении
    - правила sanitize filename
    - запрет активного контента (XSS) и явно перечисленные запрещённые типы
    - ссылку на `docs/privacy/retention_matrix.md` для attachments retention

11. [x] **Сделать:** Зафиксировать правило: вложения и их метаданные не должны утекать в логи/ответы без redaction и без доступа по ролям (least privilege).  
    **Проверка (pass/fail):** существует `docs/privacy/access_control_policy.md`, содержит:
    - роли доступа к attachments
    - запрет “public by default”
    - правило логирования: не писать attachment bytes и не писать PII метаданные без redaction

12. [x] **Сделать:** Зафиксировать требования шифрования: TLS in-transit; encryption at rest для хранилищ событий/аудита/вложений; управление ключами и ротация.  
    **Проверка (pass/fail):** существует `docs/privacy/encryption_policy.md`, содержит:
    - требования TLS
    - требования encryption-at-rest для каждого типа хранилища
    - правила key rotation (период + ответственный компонент)

13. [ ] **Сделать:** Зафиксировать региональные профили privacy (если используются): различия retention/DSR/экспорта по регионам и механизм выбора профиля.  
    **Проверка (pass/fail):** существует `docs/privacy/regional_profiles.md`, содержит:
    - список регионов/профилей
    - различия retention/DSR (таблично)
    - механизм выбора профиля (конфиг, ключ/параметр) и default profile

14. [ ] **Сделать:** Определить тестовую матрицу privacy и минимальные обязательные тесты (unit/integration) для redaction + attachments + DSR.  
    **Проверка (pass/fail):** существует `docs/privacy/test_matrix.md`, содержит:
    - unit: redaction rules (секреты/PII) + генерация `privacy.redaction_applied`
    - integration: секреты не попадают в логи/ответы/аудит
    - integration: attachments MIME/magic/max-size + sanitize filename + запрет активного контента
    - integration: DSR export/delete path (проверка по артефактам)

15. [ ] **Сделать:** Добавить CI gate Stage 02: проверка наличия документов Stage 02 + минимальная валидация содержимого ключевых требований (через grep/простые проверки).  
    **Проверка (pass/fail):** существует исполняемый скрипт `scripts/ci/check_privacy_stage02.sh` и он запускается в CI workflow; скрипт:
    - проверяет существование всех файлов из раздела “Документация (RU)”
    - проверяет минимальный контент:
      - `docs/privacy/redaction_policy.md` содержит `privacy.redaction_applied` и `configurable rules` и `observability_gap.redaction_failed`
      - `docs/privacy/retention_matrix.md` содержит таблицу с упоминанием `events`, `incidents`, `audit`, `attachments`
      - `docs/privacy/attachments_security.md` содержит `MIME`, `magic bytes`, `max size`, `sanitize filename`
      - `docs/privacy/pii_surface.md` содержит `RawEvent`, `Incident`, `AuditEntry`, `AttachmentMeta`
    - завершается с кодом 0 на зелёном состоянии и с кодом 1 при нарушении любой проверки.

## Документация (RU)
- docs/privacy/data_classification.md
- docs/privacy/pii_surface.md
- docs/privacy/data_minimization_policy.md
- docs/privacy/redaction_policy.md
- docs/privacy/retention_matrix.md
- docs/privacy/dsr_process.md
- docs/privacy/attachments_security.md
- docs/privacy/access_control_policy.md
- docs/privacy/encryption_policy.md
- docs/privacy/regional_profiles.md
- docs/privacy/test_matrix.md
- scripts/ci/check_privacy_stage02.sh

## Тестирование
- unit: redaction rules + генерация `privacy.redaction_applied`
- integration: секреты не попадают в логи/ответы/аудит (pre-write redaction)
- integration: attachments (MIME/magic/max-size/sanitize/XSS)
- integration: DSR (export/delete) по артефактам

## CI gate
- `scripts/ci/check_privacy_stage02.sh` в CI для каждого PR в main
- тесты privacy (unit/integration) зелёные

## DoD
- Privacy baseline однозначен: PII surface определён, redaction rules конфигурируемы, `privacy.redaction_applied` обязателен, `observability_gap.redaction_failed` определён, вложения безопасны, retention и DSR определены, CI gate Stage 02 проходит.

## Метаданные
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение схем RawEvent/Incident/Audit/attachments; изменение redaction rules; изменение retention; изменение региональных профилей


## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
