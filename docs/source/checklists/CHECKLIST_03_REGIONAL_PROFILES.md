A) Полный запрет опциональности:
# CHECKLIST 03 — Региональные профили (global/eu/ru/airgapped)
Файл: CHECKLIST_03_REGIONAL_PROFILES.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение требований профилей; изменение механизма packs/обновлений; изменение правил egress; изменение retention/DSR; изменение guardrails

## Цель
Определить профили конфигурации и правила их смены; обеспечить детерминированные guardrails профиля (startup/apply-config), корректную миграцию/валидацию данных при смене профиля, и офлайн-обновление packs в airgapped с проверкой подписи и совместимости.

## Границы
Технические требования к конфигурации и операционные процедуры.

## Зависимости
- CHECKLIST_01_GOVERNANCE_SRE.md
- CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md

## Шаги (строго линейно)

- [x] **1. Сделать:** Определить состав профилей `global`, `eu`, `ru`, `airgapped` как набор детерминированных параметров с фиксированными значениями.
  - [x] Каждый параметр профиля задаётся конкретным значением (число/строка/enum/список), например `retention_days = 30`
  - [x] Запрещены ссылки вида “как в global/как в другом профиле” и любые непрямые значения
  - [x] storage/data-residency constraints
  - [x] retention overrides
  - [x] export constraints
  - [x] network egress constraints
  - [x] updates/packs policy
  - [x] logging/telemetry constraints
  - [x] **Проверка (pass/fail):** существует `docs/compliance/profiles.md`, содержит разделы `profile: global/eu/ru/airgapped`, и для каждого профиля перечислены параметры из списка выше в явном виде с конкретными значениями (без ссылок на другие профили).

- [x] **2. Сделать:** Зафиксировать единый идентификатор профиля и способ выбора профиля при запуске.
  - [x] `profile_id` выбирается только через конфиг (имя ключа фиксировано)
  - [x] запрет автодетекта по окружению без конфигурации
  - [x] `effective_profile_id` вычисляется детерминированно
  - [x] `effective_profile_id` логируется (без секретов/PII)
  - [x] `effective_profile_id` доступен для диагностики через API или метрику (одно фиксированное решение)
  - [x] **Проверка (pass/fail):** `docs/compliance/profiles.md` содержит раздел `profile selection` с:
    - именем конфиг-поля `profile_id`
    - правилом вычисления `effective_profile_id`
    - правилом логирования `effective_profile_id`
    - описанием доступа через API/метрику (конкретно: где и под каким именем)

- [x] **3. Сделать:** Описать смену профиля как единственную допустимую операцию переключения (процедура фиксирована).
  - [x] остановить ingest
  - [x] остановить Core
  - [x] применить новую конфигурацию (включая `profile_id`)
  - [x] стартовать Core
  - [x] выполнить проверку guardrails профиля (шаг 6)
  - [x] стартовать ingest
  - [x] **Проверка (pass/fail):** `docs/compliance/profiles.md` содержит раздел `profile switch procedure` с ровно этими шагами в указанном порядке.

- [x] **4. Сделать:** Описать матрицу совместимости переходов профилей и требования к миграции/валидации данных.
  - [x] список допустимых переходов `from → to`
  - [x] для каждого допустимого перехода: обязательные действия (migrate/validate/purge/reindex) и критерий “готово”
  - [x] для каждого недопустимого перехода: явный запрет и причина
  - [x] **Проверка (pass/fail):** `docs/compliance/profiles.md` содержит раздел `migration/validation` и таблицу `transition matrix` со всеми профилями и правилами для каждого `from → to`.

- [x] **5. Сделать:** Зафиксировать правила data residency отдельно от описания профилей.
  - [x] перечислены типы данных: events/incidents/audit/attachments
  - [x] матрица `profile_id → allowed residency`
  - [x] правило блокировки при нарушении (startup fail или reject apply-config)
  - [x] **Проверка (pass/fail):** существует `docs/compliance/data_residency.md`, содержит все пункты выше.

- [x] **6. Сделать:** Описать guardrails проверки профиля при запуске и при применении новой конфигурации.
  - [x] проверка retention
  - [x] проверка export
  - [x] проверка egress
  - [x] проверка residency
  - [x] проверка updates/packs
  - [x] правило “fail closed” (блокировать запуск/применение)
  - [x] **Проверка (pass/fail):** существует `docs/compliance/profile_guards.md`, содержит список проверок и правило “fail closed”.

- [x] **7. Сделать:** Описать событие `observability_gap.profile_violation` для любого несоответствия профиля.
  - [x] событие регистрируется в snapshot/stream
  - [x] evidence_min: что нарушено, профиль, параметр, текущие значения
  - [x] зарегистрировано в реестре `observability_gap.*` (Stage 01) с `incident_rule` и `action_ref`
  - [x] `action_ref` указывает на конкретный runbook в репозитории: `docs/runbooks/profile_violation.md`
  - [x] **Проверка (pass/fail):** `docs/compliance/profile_guards.md` содержит раздел `observability_gap.profile_violation` с перечисленными требованиями; `docs/runbooks/profile_violation.md` существует.

- [x] **8. Сделать:** Зафиксировать связку Stage 03 ↔ Stage 02 (privacy).
  - [x] retention/DSR различия по профилям в compliance-доках ссылаются на `docs/privacy/regional_profiles.md`
  - [x] при конфликте правил — генерируется `observability_gap.profile_violation`
  - [x] **Проверка (pass/fail):** в `docs/compliance/profiles.md` есть раздел `privacy linkage` со ссылками и правилом конфликта → `observability_gap.profile_violation`.

- [x] **9. Сделать:** Описать офлайн-обновление packs для `airgapped` как фиксированную процедуру.
  - [x] доставка архива packs
  - [x] проверка подписи (ключ/сертификат указан)
  - [x] проверка целостности (hash)
  - [x] ручная установка
  - [x] тест совместимости (version check)
  - [x] smoke-check
  - [x] **Проверка (pass/fail):** существует `docs/compliance/airgapped.md`, содержит раздел `offline packs update` с указанными шагами в указанном порядке.

- [x] **10. Сделать:** Зафиксировать требования к keys для подписи packs (airgapped).
  - [x] путь в репозитории для публичного ключа/сертификата
  - [x] процедура ротации ключа
  - [x] запрет установки packs без валидной подписи
  - [x] **Проверка (pass/fail):** `docs/compliance/airgapped.md` содержит раздел `signature keys` со всеми пунктами выше.

- [x] **11. Сделать:** Добавить тестовую матрицу Stage 03 (обязательные интеграционные тесты) и обеспечить автоматизацию.
  - [x] профиль меняется только через процедуру stop→stop→apply→start→guard→start
  - [x] airgapped packs update отклоняется без подписи
  - [x] airgapped packs update отклоняется при несовместимости версий
  - [x] нарушение residency/egress/retention профиля даёт `observability_gap.profile_violation` и блокирует запуск/применение
  - [x] эти тесты автоматизированы
  - [x] эти тесты включены в CI workflow
  - [x] **Проверка (pass/fail):** существует `docs/compliance/test_matrix.md`, содержит тесты с входами/ожидаемым результатом, и явно указано:
    - где лежат автотесты (пути)
    - как они запускаются в CI (workflow/target/command)

- [x] **12. Сделать:** Добавить CI gate Stage 03 (наличие файлов + минимальная валидация содержимого).
  - [x] существует `scripts/ci/check_regional_profiles_stage03.sh`
  - [x] скрипт исполняемый
  - [x] скрипт запускается в CI workflow
  - [x] проверяет наличие всех файлов из раздела “Документация (RU)”
  - [x] `docs/compliance/profiles.md` содержит `profile selection`, `profile switch procedure`, `migration/validation`, `transition matrix`, `profile_id`
  - [x] `docs/compliance/profile_guards.md` содержит `fail closed` и `observability_gap.profile_violation`
  - [x] `docs/compliance/airgapped.md` содержит `offline packs update` и `signature keys`
  - [x] `docs/compliance/data_residency.md` содержит матрицу `profile_id → allowed`
  - [x] `docs/compliance/test_matrix.md` содержит строку `автоматизированы` и `CI`
  - [x] **Проверка (pass/fail):** CI зелёный; при удалении любого обязательного раздела/файла скрипт падает (exit 1).

## Документация (RU)
- [x] docs/compliance/profiles.md
- [x] docs/compliance/data_residency.md
- [x] docs/compliance/profile_guards.md
- [x] docs/compliance/airgapped.md
- [x] docs/compliance/test_matrix.md
- [x] docs/runbooks/profile_violation.md
- [x] scripts/ci/check_regional_profiles_stage03.sh

## Тестирование
- [x] integration: смена профиля только по процедуре (шаг 3)
- [x] integration: guardrails блокируют запуск/применение при нарушении (шаги 6–7)
- [x] integration: airgapped update — отказ без подписи/несовместимость; успех при валидных условиях (шаги 9–10)

## CI gate
- [x] `scripts/ci/check_regional_profiles_stage03.sh` включён в CI для PR в main
- [x] автотесты Stage 03 включены в CI и зелёные

## DoD
- [x] Профили и параметры заданы однозначно (без ссылок “как в другом профиле”)
- [x] Выбор/смена профиля детерминированы и защищены guardrails
- [x] `effective_profile_id` доступен для диагностики через API/метрику
- [x] Матрица переходов определена и проверяется
- [x] `observability_gap.profile_violation` определён и зарегистрирован; runbook `docs/runbooks/profile_violation.md` существует
- [x] Airgapped packs update (подпись/совместимость) определён
- [x] CI gate Stage 03 проходит
