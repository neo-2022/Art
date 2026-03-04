A) Полный запрет опциональности:
# CHECKLIST 24 — Release/Upgrade/Regression
Файл: CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение релизной политики; изменение signing; изменение матрицы совместимости; изменение downgrade/миграций

## Цель
Релиз однозначен и проверяем: manual release процесс; upgrade N→N+1 и downgrade N→N-1 с сохранением данных обязателен; cosign signing+verify для Docker образов обязателен; RELEASE_CHECKLIST обязателен перед тегом; отказ verify порождает `observability_gap.release_signing_failed`.

## Границы
Release/upgrade/regression процесс и тесты. Не включает разработку функционала Core/Agent.

## Зависимости
- CHECKLIST 23 — Ops/Deploy/Runbooks/DR
- CHECKLIST 04 — Secure SDLC + Supply-chain

## Шаги (строго линейно)

- [ ] **1. Сделать:** Зафиксировать manual release процесс (SemVer + CHANGELOG) и запретить “релиз локально”.
  - [ ] Релиз создаётся только через CI workflow (локальные релизы запрещены)
  - [ ] Версионирование фиксировано: SemVer
  - [ ] CHANGELOG обновляется в PR до тега
  - [ ] Тегирование выполняется только после выполнения RELEASE_CHECKLIST (шаг 4)
  - [ ] **Проверка (pass/fail):** `docs/release/release_process.md` существует и содержит все пункты выше в явном виде.

- [ ] **2. Сделать:** Ввести upgrade/downgrade regression suite (автоматизировано): N→N+1 и N→N-1 с сохранением данных.
  - [ ] Suite имеет фиксированное имя запуска: `make test-upgrade-downgrade`
  - [ ] Upgrade сценарий N→N+1:
    - [ ] поднимаем N, ingest 100 событий
    - [ ] создаём минимум 2 инцидента (по правилам/тестовым триггерам)
    - [ ] обновляем до N+1 (миграции выполняются по Stage 23)
    - [ ] проверяем: инциденты читаются через API, snapshot/stream работают
  - [ ] Downgrade сценарий N→N-1:
    - [ ] поднимаем N, ingest 100 событий, создаём минимум 2 инцидента
    - [ ] выполняем downgrade до N-1
    - [ ] проверяем: инциденты читаются через API, snapshot/stream работают
  - [ ] Критерий “сохранение данных” фиксирован:
    - [ ] после upgrade/downgrade количество инцидентов равно исходному
    - [ ] `ack.upto_seq` монотонен на прогоне
  - [ ] **Проверка (pass/fail):** suite запускается локально и в CI и зелёная.

- [ ] **3. Сделать:** cosign: подписывать Docker образы и проверять подпись в CI (sign + verify обязательны).
  - [ ] Подписываются Docker образы фиксированного набора:
    - [ ] `art-core` image
    - [ ] `art-agent` image
  - [ ] Инструмент: `cosign` (sigstore)
  - [ ] Режим: keyless OIDC (из Stage 04)
  - [ ] В CI есть workflow job `image-signing-verify`:
    - [ ] выполняет build images
    - [ ] выполняет cosign sign
    - [ ] выполняет cosign verify
    - [ ] падает при любой ошибке verify
  - [ ] **Проверка (pass/fail):** job `image-signing-verify` зелёный на релизном workflow и на PR (где применимо).

- [ ] **4. Сделать:** RELEASE_CHECKLIST обязателен перед тегом (enforce).
  - [ ] существует файл `RELEASE_CHECKLIST.md`
  - [ ] `RELEASE_CHECKLIST.md` содержит минимум:
    - [ ] версия (SemVer)
    - [ ] ссылка на CHANGELOG entry
    - [ ] ссылка на успешный прогон `make test-upgrade-downgrade`
    - [ ] ссылка на успешный `image-signing-verify`
    - [ ] ссылка на DR/backup требования (Stage 23)
  - [ ] В release workflow enforce правило: релиз/тегирование запрещено, если `RELEASE_CHECKLIST.md` не обновлён в текущем PR/коммите релиза
  - [ ] **Проверка (pass/fail):** induced test/проверка: попытка релиза без обновления `RELEASE_CHECKLIST.md` падает в CI.

- [ ] **5. Сделать:** `observability_gap.release_signing_failed` при провале signing verify.
  - [ ] Событие генерируется при любой ошибке verify подписи образов в release pipeline
  - [ ] Событие попадает в snapshot/stream (через startup backlog, если релизный пайплайн вне Core; фиксированная доставка: запись в локальный буфер и публикация при следующем старте Core)
  - [ ] evidence_min:
    - [ ] image_name
    - [ ] image_digest
    - [ ] cosign_error
    - [ ] trace_id
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/release_signing_failed.md`
  - [ ] **Проверка (pass/fail):** induced test ломает verify (например, подменяет digest) и проверяет:
    - [ ] падение verify шага в CI
    - [ ] наличие `observability_gap.release_signing_failed` в snapshot/stream после следующего старта Core.

## Документация (RU)
- [ ] docs/release/release_process.md
- [ ] docs/release/versioning.md
- [ ] docs/release/compat_matrix.md
- [ ] docs/release/downgrade.md
- [ ] docs/runbooks/release_signing_failed.md
- [ ] RELEASE_CHECKLIST.md
- [ ] CHANGELOG.md

## Тестирование
- [ ] integration: `make test-upgrade-downgrade` (шаг 2)
- [ ] security: `image-signing-verify` (шаг 3)
- [ ] induced: signing verify fail → `observability_gap.release_signing_failed` (шаг 5)

## CI gate
- [ ] CI job `test-upgrade-downgrade` существует и зелёный
- [ ] CI job `image-signing-verify` существует и зелёный
- [ ] CI job `stage24-docs-gate` существует и запускается на PR в main
- [ ] `stage24-docs-gate` запускает `scripts/ci/check_release_stage24_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/release/release_process.md` содержит `manual` и `CI` и `SemVer`
    - [ ] `docs/release/downgrade.md` содержит `N-1` и `инциденты читаются`
    - [ ] `RELEASE_CHECKLIST.md` содержит `test-upgrade-downgrade` и `image-signing-verify`
    - [ ] `docs/runbooks/release_signing_failed.md` содержит `mitigations` и `verification`
    - [ ] `docs/governance/observability_gap_registry.md` содержит `release_signing_failed`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Manual release процесс задокументирован и enforce’ится CI.
- [ ] Upgrade/downgrade suite автоматизирована и зелёная в CI.
- [ ] cosign sign+verify для Docker образов обязательны и зелёные.
- [ ] RELEASE_CHECKLIST обязателен и реально блокирует релиз без заполнения.
- [ ] `observability_gap.release_signing_failed` реализован, зарегистрирован и покрыт induced test.
- [ ] CI gate Stage 24 зелёный.

