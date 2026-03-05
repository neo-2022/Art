A) Полный запрет опциональности:
# CHECKLIST 19 — Packs framework
Файл: CHECKLIST_19_PACKS_FRAMEWORK.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение формата packs; изменение signing; изменение dependencies; изменение политики airgapped; изменение ключей подписи

## Цель
Packs без двусмысленности: автообновление запрещено (только ручная установка); подпись cosign обязательна и проверяется при install; dependencies обязательны в формате; install failures порождают `observability_gap.pack_install_failed` с runbook; CI gate проверяет не только наличие файлов, но и минимальное содержимое документов.

## Границы
Framework packs: формат, signing/verify, установка, разрешение зависимостей, ошибки установки и их наблюдаемость.  
Не включает содержимое конкретных packs.

## Зависимости
- CHECKLIST 04 — Secure SDLC + Supply-chain (cosign policy, OIDC, verify)
- CHECKLIST 03 — Regional profiles (airgapped offline update)
- CHECKLIST 01 — Governance/SRE (реестр `observability_gap.*`, runbooks)
- CHECKLIST 13–18 (pipeline/agent контекст использования packs)

## Статус перепроверки
- Перепроверка завершена: runtime, тесты, docs и CI gate подтверждены.

## Шаги (строго линейно)

- [x] **1. Сделать:** Запретить автообновления packs: только ручная установка.
  - [x] В runtime отсутствует любой механизм автообновления packs (таймер/фоновые проверки/“update check”)
  - [x] Единственный способ обновить packs: явная команда/endpoint install (ручное действие)
  - [x] Для airgapped профиля установка выполняется только из локального файла (offline)
  - [x] **Проверка (pass/fail):** `docs/packs/versioning.md` содержит:
    - [x] “автообновления запрещены”
    - [x] “только ручная установка”
    - [x] “airgapped: только offline файл”

- [x] **2. Сделать:** Реализовать cosign подпись packs и обязательную проверку подписи при install.
  - [x] Формат pack включает подпись/attestation (layout описан в spec; шаг 4)
  - [x] Install всегда выполняет verify подписи cosign
  - [x] Install отклоняет pack при:
    - [x] отсутствующей подписи
    - [x] невалидной подписи
    - [x] неподходящем issuer/identity (политика фиксирована в docs)
  - [x] **Проверка (pass/fail):** integration test `pack_install_bad_signature_fails` подтверждает:
    - [x] install завершился ошибкой
    - [x] pack не активирован
    - [x] сгенерировано событие `observability_gap.pack_install_failed` (шаг 5)

- [x] **3. Сделать:** Реализовать dependencies в формате pack и разрешение зависимостей.
  - [x] В manifest packs поле `dependencies` обязательно и имеет формат:
    - [x] `dependencies: [{name: string, version_range: string}]`
  - [x] Версионирование packs фиксировано: SemVer
  - [x] Алгоритм разрешения зависимостей фиксирован:
    - [x] если любая зависимость не удовлетворена → install fail
    - [x] если зависимость удовлетворена несколькими версиями → выбирается максимальная подходящая (одно фиксированное решение)
    - [x] циклические зависимости запрещены (cycle → fail)
  - [x] **Проверка (pass/fail):** integration test `pack_deps_resolution` проверяет:
    - [x] успешную установку при удовлетворённых deps
    - [x] fail при missing deps
    - [x] fail при cycle
    - [x] выбор максимальной подходящей версии

- [x] **4. Сделать:** Зафиксировать формат packs v1 (spec) и неизменяемые требования.
  - [x] существует `docs/packs/spec.md`
  - [x] spec содержит фиксированный layout (однозначно):
    - [x] `manifest.yaml` (name, version, dependencies, entrypoints)
    - [x] `payload/` (содержимое pack)
    - [x] `signatures/` (cosign artifacts: signature/attestation)
  - [x] spec фиксирует требования:
    - [x] `name` (строка, уникальная)
    - [x] `version` (SemVer)
    - [x] `dependencies` (обязательное поле, шаг 3)
    - [x] `entrypoints` (обязательное поле; список строк)
  - [x] **Проверка (pass/fail):** `docs/packs/spec.md` содержит все пункты выше в явном виде.

- [x] **5. Сделать:** Реализовать gap при невозможности установить pack: `observability_gap.pack_install_failed`.
  - [x] `observability_gap.pack_install_failed` генерируется при любой ошибке install (signature/deps/layout/io)
  - [x] событие попадает в snapshot/stream
  - [x] событие содержит evidence_min:
    - [x] pack_name
    - [x] pack_version
    - [x] fail_stage (enum: layout|signature|deps|io|activate)
    - [x] error (строка)
    - [x] trace_id
  - [x] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/pack_install_failed.md`
  - [x] **Проверка (pass/fail):** induced test форсит ошибку install (например missing dependency) и проверяет:
    - [x] install fail
    - [x] событие `observability_gap.pack_install_failed` видно в snapshot/stream
    - [x] `action_ref` указывает на `docs/runbooks/pack_install_failed.md`

## Документация (RU)
- [x] docs/packs/spec.md
- [x] docs/packs/versioning.md
- [x] docs/packs/signing.md
- [x] docs/runbooks/pack_install_failed.md

## Тестирование
- [x] integration: `pack_install_bad_signature_fails`
- [x] integration: `pack_deps_resolution`
- [x] integration: `pack_install_success`
- [x] induced: `pack_install_failed_generates_gap_event`

## CI gate
- [x] CI job `packs-tests` существует и запускается на PR в main; job зелёный
- [x] CI job `stage19-docs-gate` существует и запускается на PR в main
- [x] `stage19-docs-gate` запускает `scripts/ci/check_packs_stage19_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/packs/versioning.md` содержит `автообновления запрещены` и `ручная установка`
    - [x] `docs/packs/spec.md` содержит `manifest.yaml` и `dependencies`
    - [x] `docs/packs/signing.md` содержит `cosign` и `verify`
    - [x] `docs/runbooks/pack_install_failed.md` содержит `mitigations` и `verification`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Автообновления packs отсутствуют; только ручная установка (включая airgapped offline).
- [x] cosign подпись обязательна; verify выполняется при install; есть тест “bad signature fails”.
- [x] dependencies обязательны; разрешение deps детерминировано и покрыто тестами.
- [x] `observability_gap.pack_install_failed` реализован, зарегистрирован и имеет runbook.
- [x] CI gate Stage 19 зелёный.

