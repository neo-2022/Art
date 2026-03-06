A) Полный запрет опциональности:
# CHECKLIST 19 — Packs framework
Файл: CHECKLIST_19_PACKS_FRAMEWORK.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение формата packs; изменение signing; изменение dependencies; изменение политики airgapped; изменение ключей подписи
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Packs без двусмысленности: автообновление запрещено (только ручная установка); подпись cosign обязательна и проверяется при install; dependencies обязательны в формате; install failures порождают `observability_gap.pack_install_failed` с runbook; pack обязан нести машиночитаемое знание о внешних системах/источниках сигналов; CI gate проверяет не только наличие файлов, но и минимальное содержимое документов.

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

- [ ] **1. Сделать:** Запретить автообновления packs: только ручная установка.
  - [ ] В runtime отсутствует любой механизм автообновления packs (таймер/фоновые проверки/“update check”)
  - [ ] Единственный способ обновить packs: явная команда/endpoint install (ручное действие)
  - [ ] Для airgapped профиля установка выполняется только из локального файла (offline)
  - [ ] **Проверка (pass/fail):** `docs/packs/versioning.md` содержит:
    - [ ] “автообновления запрещены”
    - [ ] “только ручная установка”
    - [ ] “airgapped: только offline файл”

- [ ] **2. Сделать:** Реализовать cosign подпись packs и обязательную проверку подписи при install.
  - [ ] Формат pack включает подпись/attestation (layout описан в spec; шаг 4)
  - [ ] Install всегда выполняет verify подписи cosign
  - [ ] Install отклоняет pack при:
    - [ ] отсутствующей подписи
    - [ ] невалидной подписи
    - [ ] неподходящем issuer/identity (политика фиксирована в docs)
  - [ ] **Проверка (pass/fail):** integration test `pack_install_bad_signature_fails` подтверждает:
    - [ ] install завершился ошибкой
    - [ ] pack не активирован
    - [ ] сгенерировано событие `observability_gap.pack_install_failed` (шаг 5)

- [ ] **3. Сделать:** Реализовать dependencies в формате pack и разрешение зависимостей.
  - [ ] В manifest packs поле `dependencies` обязательно и имеет формат:
    - [ ] `dependencies: [{name: string, version_range: string}]`
  - [ ] Версионирование packs фиксировано: SemVer
  - [ ] Алгоритм разрешения зависимостей фиксирован:
    - [ ] если любая зависимость не удовлетворена → install fail
    - [ ] если зависимость удовлетворена несколькими версиями → выбирается максимальная подходящая (одно фиксированное решение)
    - [ ] циклические зависимости запрещены (cycle → fail)
  - [ ] **Проверка (pass/fail):** integration test `pack_deps_resolution` проверяет:
    - [ ] успешную установку при удовлетворённых deps
    - [ ] fail при missing deps
    - [ ] fail при cycle
    - [ ] выбор максимальной подходящей версии

- [ ] **4. Сделать:** Зафиксировать формат packs v1 (spec) и неизменяемые требования.
  - [ ] существует `docs/packs/spec.md`
  - [ ] spec содержит фиксированный layout (однозначно):
    - [ ] `manifest.yaml` (name, version, dependencies, entrypoints)
    - [ ] `payload/` (содержимое pack)
    - [ ] `signatures/` (cosign artifacts: signature/attestation)
  - [ ] spec фиксирует требования:
    - [ ] `name` (строка, уникальная)
    - [ ] `version` (SemVer)
    - [ ] `dependencies` (обязательное поле, шаг 3)
    - [ ] `entrypoints` (обязательное поле; список строк)
  - [ ] **Проверка (pass/fail):** `docs/packs/spec.md` содержит все пункты выше в явном виде.

- [ ] **4A. Сделать:** Зафиксировать в формате pack машиночитаемое знание о внешних системах и coverage claims.
  - [ ] manifest pack содержит минимум поля:
    - [ ] `service_inventory`
    - [ ] `receiver_examples`
    - [ ] `signal_coverage_claims`
    - [ ] `telemetry_endpoints`
    - [ ] `regulatory_tags`
  - [ ] `signal_coverage_claims` перечисляет, какие сигналы pack реально покрывает (`ui_runtime`, `proxy_upstream`, `systemd`, `journald`, `net_probe`, `otlp`, `webhook` и т.п.)
  - [ ] `telemetry_endpoints` фиксирует, через какие механизмы проект отдаёт сигналы во внешний мир
  - [ ] `regulatory_tags` допускает минимум `ru_profile`, `airgapped_ready`, `certified_ready`
  - [ ] **Проверка (pass/fail):** `docs/packs/spec.md` и validation tests описывают и проверяют все поля выше.

- [ ] **5. Сделать:** Реализовать gap при невозможности установить pack: `observability_gap.pack_install_failed`.
  - [ ] `observability_gap.pack_install_failed` генерируется при любой ошибке install (signature/deps/layout/io)
  - [ ] событие попадает в snapshot/stream
  - [ ] событие содержит evidence_min:
    - [ ] pack_name
    - [ ] pack_version
    - [ ] fail_stage (enum: layout|signature|deps|io|activate)
    - [ ] error (строка)
    - [ ] trace_id
  - [ ] событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/pack_install_failed.md`
  - [ ] **Проверка (pass/fail):** induced test форсит ошибку install (например missing dependency) и проверяет:
    - [ ] install fail
    - [ ] событие `observability_gap.pack_install_failed` видно в snapshot/stream
    - [ ] `action_ref` указывает на `docs/runbooks/pack_install_failed.md`

## Документация (RU)
- [ ] docs/packs/spec.md
- [ ] docs/packs/versioning.md
- [ ] docs/packs/signing.md
- [ ] docs/packs/source_coverage.md
- [ ] docs/runbooks/pack_install_failed.md

## Тестирование
- [ ] integration: `pack_install_bad_signature_fails`
- [ ] integration: `pack_deps_resolution`
- [ ] integration: `pack_install_success`
- [ ] induced: `pack_install_failed_generates_gap_event`
- [ ] validation: manifest source coverage / telemetry_endpoints / regulatory_tags schema checks
- [ ] runtime: `scripts/tests/pack_install_runtime.sh` проверяет install из реального `packs/regart` layout (`manifest.yaml` + `payload/` + `signatures/manifest.sha256`)

## CI gate
- [ ] CI job `packs-tests` существует и запускается на PR в main; job зелёный
- [ ] CI job `packs-runtime-install` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage19-docs-gate` существует и запускается на PR в main
- [ ] `stage19-docs-gate` запускает `scripts/ci/check_packs_stage19_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет существование runtime harness `scripts/tests/pack_install_runtime.sh`
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/packs/versioning.md` содержит `автообновления запрещены` и `ручная установка`
    - [ ] `docs/packs/spec.md` содержит `manifest.yaml` и `dependencies` и `signal_coverage_claims`
    - [ ] `docs/packs/source_coverage.md` содержит `service_inventory` и `telemetry_endpoints` и `regulatory_tags`
    - [ ] `docs/packs/signing.md` содержит `cosign` и `verify`
    - [ ] `docs/runbooks/pack_install_failed.md` содержит `mitigations` и `verification`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Автообновления packs отсутствуют; только ручная установка (включая airgapped offline).
- [ ] cosign подпись обязательна; verify выполняется при install; есть тест “bad signature fails”.
- [ ] dependencies обязательны; разрешение deps детерминировано и покрыто тестами.
- [ ] Pack manifest содержит машиночитаемое знание о внешних системах/источниках/регуляторных тегах.
- [ ] `observability_gap.pack_install_failed` реализован, зарегистрирован и имеет runbook.
- [ ] CI gate Stage 19 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
