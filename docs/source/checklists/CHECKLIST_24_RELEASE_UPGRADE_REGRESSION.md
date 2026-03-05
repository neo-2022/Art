A) Полный запрет опциональности:
# CHECKLIST 24 — Release/Upgrade/Regression
Файл: CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение релизной политики; изменение signing; изменение матрицы совместимости; изменение downgrade/миграций

## Цель
Релиз однозначен и проверяем: manual release процесс; upgrade N→N+1 и downgrade N→N-1 с сохранением данных обязателен; cosign signing+verify для Docker образов обязателен; RELEASE_CHECKLIST обязателен перед тегом; отказ verify порождает `observability_gap.release_signing_failed`.

## Границы
Release/upgrade/regression процесс и тесты. Не включает разработку функционала Core/Agent.

## Зависимости
- CHECKLIST 23 — Ops/Deploy/Runbooks/DR
- CHECKLIST 04 — Secure SDLC + Supply-chain

## Шаги (строго линейно)

- [x] **1. Сделать:** Зафиксировать manual release процесс (SemVer + CHANGELOG) и запретить “релиз локально”.
  - [x] Релиз создаётся только через CI workflow (локальные релизы запрещены)
  - [x] Версионирование фиксировано: SemVer
  - [x] CHANGELOG обновляется в PR до тега
  - [x] Тегирование выполняется только после выполнения RELEASE_CHECKLIST (шаг 4)
  - [x] **Проверка (pass/fail):** `docs/release/release_process.md` существует и содержит все пункты выше в явном виде.

- [x] **2. Сделать:** Ввести upgrade/downgrade regression suite (автоматизировано): N→N+1 и N→N-1 с сохранением данных.
  - [x] Suite имеет фиксированное имя запуска: `make test-upgrade-downgrade`
  - [x] Upgrade сценарий N→N+1:
    - [x] поднимаем N, ingest 100 событий
    - [x] создаём минимум 2 инцидента (по правилам/тестовым триггерам)
    - [x] обновляем до N+1 (миграции выполняются по Stage 23)
    - [x] проверяем: инциденты читаются через API, snapshot/stream работают
  - [x] Downgrade сценарий N→N-1:
    - [x] поднимаем N, ingest 100 событий, создаём минимум 2 инцидента
    - [x] выполняем downgrade до N-1
    - [x] проверяем: инциденты читаются через API, snapshot/stream работают
  - [x] Критерий “сохранение данных” фиксирован:
    - [x] после upgrade/downgrade количество инцидентов равно исходному
    - [x] `ack.upto_seq` монотонен на прогоне
  - [x] **Проверка (pass/fail):** suite запускается локально и в CI и зелёная.

- [x] **3. Сделать:** cosign: подписывать Docker образы и проверять подпись в CI (sign + verify обязательны).
  - [x] Подписываются Docker образы фиксированного набора:
    - [x] `art-core` image
    - [x] `art-agent` image
  - [x] Инструмент: `cosign` (sigstore)
  - [x] Режим: keyless OIDC (из Stage 04)
  - [x] В CI есть workflow job `image-signing-verify`:
    - [x] выполняет build images
    - [x] выполняет cosign sign
    - [x] выполняет cosign verify
    - [x] падает при любой ошибке verify
  - [x] **Проверка (pass/fail):** job `image-signing-verify` зелёный на релизном workflow и на PR (где применимо).

- [x] **4. Сделать:** RELEASE_CHECKLIST обязателен перед тегом (enforce).
  - [x] существует файл `RELEASE_CHECKLIST.md`
  - [x] `RELEASE_CHECKLIST.md` содержит минимум:
    - [x] версия (SemVer)
    - [x] ссылка на CHANGELOG entry
    - [x] ссылка на успешный прогон `make test-upgrade-downgrade`
    - [x] ссылка на успешный `image-signing-verify`
    - [x] ссылка на DR/backup требования (Stage 23)
  - [x] В release workflow enforce правило: релиз/тегирование запрещено, если `RELEASE_CHECKLIST.md` не обновлён в текущем PR/коммите релиза
  - [x] **Проверка (pass/fail):** induced test/проверка: попытка релиза без обновления `RELEASE_CHECKLIST.md` падает в CI.

- [x] **5. Сделать:** `observability_gap.release_signing_failed` при провале signing verify.
  - [x] Событие генерируется при любой ошибке verify подписи образов в release pipeline
  - [x] Событие попадает в snapshot/stream (через startup backlog, если релизный пайплайн вне Core; фиксированная доставка: запись в локальный буфер и публикация при следующем старте Core)
  - [x] evidence_min:
    - [x] image_name
    - [x] image_digest
    - [x] cosign_error
    - [x] trace_id
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/release_signing_failed.md`
  - [x] **Проверка (pass/fail):** induced test ломает verify (например, подменяет digest) и проверяет:
    - [x] падение verify шага в CI
    - [x] наличие `observability_gap.release_signing_failed` в snapshot/stream после следующего старта Core.

## Документация (RU)
- [x] docs/release/release_process.md
- [x] docs/release/versioning.md
- [x] docs/release/compat_matrix.md
- [x] docs/release/downgrade.md
- [x] docs/runbooks/release_signing_failed.md
- [x] RELEASE_CHECKLIST.md
- [x] CHANGELOG.md

## Тестирование
- [x] integration: `make test-upgrade-downgrade` (шаг 2)
- [x] security: `image-signing-verify` (шаг 3)
- [x] induced: signing verify fail → `observability_gap.release_signing_failed` (шаг 5)

## CI gate
- [x] CI job `test-upgrade-downgrade` существует и зелёный
- [x] CI job `image-signing-verify` существует и зелёный
- [x] CI job `stage24-docs-gate` существует и запускается на PR в main
- [x] `stage24-docs-gate` запускает `scripts/ci/check_release_stage24_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/release/release_process.md` содержит `manual` и `CI` и `SemVer`
    - [x] `docs/release/downgrade.md` содержит `N-1` и `инциденты читаются`
    - [x] `RELEASE_CHECKLIST.md` содержит `test-upgrade-downgrade` и `image-signing-verify`
    - [x] `docs/runbooks/release_signing_failed.md` содержит `mitigations` и `verification`
    - [x] `docs/governance/observability_gap_registry.md` содержит `release_signing_failed`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Manual release процесс задокументирован и enforce’ится CI.
- [x] Upgrade/downgrade suite автоматизирована и зелёная в CI.
- [x] cosign sign+verify для Docker образов обязательны и зелёные.
- [x] RELEASE_CHECKLIST обязателен и реально блокирует релиз без заполнения.
- [x] `observability_gap.release_signing_failed` реализован, зарегистрирован и покрыт induced test.
- [x] CI gate Stage 24 зелёный.

