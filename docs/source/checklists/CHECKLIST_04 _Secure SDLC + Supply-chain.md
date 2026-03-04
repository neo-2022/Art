A) Полный запрет опциональности:
# CHECKLIST 04 — Secure SDLC + Supply-chain
Файл: CHECKLIST_04 _Secure SDLC + Supply-chain.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение CI/релизного процесса; смена инструментов подписи; изменение политики зависимостей; изменение инфраструктуры сборки

## Цель
Определить и внедрить требования Secure SDLC и supply-chain security: чистые и воспроизводимые сборки, защита веток/тегов, подписанные коммиты, SAST/SCA/license/secrets, SBOM, provenance/signing/verification, pinning CI зависимостей и GitHub Actions, защита релизного контура.

## Границы
Политики + обязательные CI gates в рамках репозитория (без двусмысленностей).  
Процессы Governance/SRE, incident/severity/audit — в Stage 01; здесь — security SDLC и supply-chain.

## Зависимости
- CHECKLIST_01_GOVERNANCE_SRE.md
- CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md
- CHECKLIST_03_REGIONAL_PROFILES.md

## Шаги (строго линейно)

- [ ] **1. Сделать:** Описать политику Secure SDLC (общая) и требования “clean build / reproducible build”.
  - [ ] сборка выполняется в чистом окружении CI (без использования локальных артефактов)
  - [ ] зависимости фиксируются lock-файлами и/или pinned версиями
  - [ ] сборка детерминирована: одинаковый вход → одинаковый результат
  - [ ] для релизных сборок: хэш каждого релизного артефакта совпадает при повторных сборках из одного и того же коммита (rebuild from same commit → identical artifact hash)
  - [ ] запрещено использовать “latest” для инструментов сборки/линтеров/сканеров в CI
  - [ ] **Проверка (pass/fail):** существует `docs/security/secure_sdlc_policy.md`, содержит все пункты выше явно, включая требование совпадения хэша артефактов при повторной релизной сборке из того же коммита.

- [ ] **2. Сделать:** Описать branch policy + tag/release policy (enforce через branch protection) без двусмысленностей, включая точные required status checks.
  - [ ] прямые коммиты в `main` запрещены
  - [ ] изменения попадают в `main` только через PR
  - [ ] required status checks в `main` включены
  - [ ] required reviews включены (минимум 1)
  - [ ] CODEOWNERS включён и влияет на required reviews
  - [ ] force-push в `main` запрещён
  - [ ] теги релизов защищены (запрет переписывания релизных тегов)
  - [ ] required status checks для `main` заданы точным списком имён (без “и т.п.”):
    - [ ] `security-stage04 / sdlc-gate`
    - [ ] `security-stage04 / sast`
    - [ ] `security-stage04 / sca`
    - [ ] `security-stage04 / license`
    - [ ] `security-stage04 / secrets`
  - [ ] **Проверка (pass/fail):** существует `docs/security/branch_tag_policy.md`, содержит все пункты выше явно, включая полный список required status checks с точными именами.

- [ ] **3. Сделать:** Зафиксировать требование подписанных коммитов в `main` и правило проверки.
  - [ ] каждый коммит в `main` имеет “Verified” подпись в UI GitHub (единый критерий)
  - [ ] merge в `main` блокируется, если коммит(ы) не “Verified”
  - [ ] **Проверка (pass/fail):** `docs/security/branch_tag_policy.md` содержит требование “Verified commits only in main” и требование блокировки merge при нарушении.

- [ ] **4. Сделать:** Зафиксировать политику pinning supply-chain в CI (GitHub Actions и внешние инструменты), включая запрет удалённых composite actions.
  - [ ] GitHub Actions в workflow закреплены на commit SHA (запрещены `@vX`, `@main`, `@master`)
  - [ ] удалённые composite actions запрещены
  - [ ] разрешены только локальные composite actions из репозитория (`uses: ./.github/actions/...`)
  - [ ] внешние CLI инструменты (semgrep/gitleaks/osv/syft/cosign и т.п.) закреплены по версии
  - [ ] разрешённые источники загрузки инструментов перечислены (GitHub Releases/официальные registries)
  - [ ] **Проверка (pass/fail):** существует `docs/security/ci_pinning_policy.md`, содержит все пункты выше явно.

- [ ] **5. Сделать:** Описать SAST policy и обязательные правила (PR gate + baseline).
  - [ ] выбран единый SAST инструмент: `semgrep`
  - [ ] правила semgrep закреплены по версии (ruleset pinned)
  - [ ] SAST выполняется на каждом PR в `main`
  - [ ] политика фейла: найденные issues уровня “error” блокируют merge
  - [ ] **Проверка (pass/fail):** существует `docs/security/sast_policy.md`, содержит все пункты выше явно.

- [ ] **6. Сделать:** Описать SCA + license checks policy (vuln + лицензии) и PR gate.
  - [ ] SCA выполняется на каждом PR в `main`
  - [ ] выбран единый источник уязвимостей: OSV
  - [ ] выбран инструмент SCA: `osv-scanner`
  - [ ] license checks выполняются на каждом PR в `main`
  - [ ] политика фейла: запрещённые лицензии блокируют merge
  - [ ] **Проверка (pass/fail):** существует `docs/security/sca_policy.md`, содержит:
    - [ ] инструмент `osv-scanner`
    - [ ] правила фейла по severity (критерии перечислены)
    - [ ] список запрещённых лицензий (явный список)
    - [ ] правило блокировки merge при нарушении

- [ ] **7. Сделать:** Описать secrets scanning policy и PR gate.
  - [ ] выбран инструмент: `gitleaks`
  - [ ] secrets scan выполняется на каждом PR в `main` и на push в `main`
  - [ ] политика фейла: любые найденные secrets блокируют merge
  - [ ] исключения допускаются только через allowlist-файл, который перечисляет конкретные пути/паттерны и проходит code review
  - [ ] **Проверка (pass/fail):** существует `docs/security/secrets_policy.md`, содержит все пункты выше явно.

- [ ] **8. Сделать:** Описать SBOM policy: генерация, формат, хранение, связка с релизом.
  - [ ] выбран инструмент: `syft`
  - [ ] формат SBOM: SPDX JSON
  - [ ] SBOM генерируется для каждого релиза
  - [ ] SBOM прикладывается к релизным артефактам и публикуется как релизный asset
  - [ ] **Проверка (pass/fail):** существует `docs/security/sbom_policy.md`, содержит все пункты выше явно.

- [ ] **9. Сделать:** Описать provenance/signing policy (sigstore/cosign) для релизных артефактов и правило verify, включая точный перечень подписываемых артефактов.
  - [ ] выбран инструмент подписи: `cosign` (sigstore)
  - [ ] режим подписи: keyless через OIDC GitHub Actions
  - [ ] подписываются все релизные артефакты из фиксированного перечня:
    - [ ] `agent/dist/*`
    - [ ] `ui/dist/*`
    - [ ] `sbom.spdx.json`
    - [ ] `checksums.txt`
  - [ ] verify выполняется в CI как обязательный gate для релизов
  - [ ] подписи/attestation публикуются вместе с релизом
  - [ ] **Проверка (pass/fail):** существует `docs/security/provenance_signing.md`, содержит все пункты выше явно, включая перечень артефактов.

- [ ] **10. Сделать:** Зафиксировать policy для dependency updates (автообновления) и правило “безопасного обновления”.
  - [ ] включён механизм PR-обновлений зависимостей (Dependabot)
  - [ ] PR обновления зависимостей проходит те же security gates (SAST/SCA/license/secrets)
  - [ ] запрещены апдейты зависимостей без PR
  - [ ] **Проверка (pass/fail):** существует `docs/security/dependency_update_policy.md`, содержит:
    - [ ] выбранный механизм (Dependabot)
    - [ ] правило PR-only
    - [ ] правило прохождения security gates

- [ ] **11. Сделать:** Зафиксировать release hardening: кто может делать релиз, откуда берутся артефакты, запрет локальных релизов.
  - [ ] релиз создаётся только из CI workflow (локальные релизы запрещены)
  - [ ] источник релиза: тег, созданный через PR/CI процедуру
  - [ ] релизный workflow требует зелёных security jobs перед публикацией
  - [ ] **Проверка (pass/fail):** существует `docs/security/release_hardening.md`, содержит все пункты выше явно.

- [ ] **12. Сделать:** Реализовать CI workflow Stage 04: security jobs и gates.
  - [ ] существует `.github/workflows/security_stage04.yml`
  - [ ] workflow имеет имя `security-stage04` (точно)
  - [ ] workflow запускается на PR в `main` и на push в `main`
  - [ ] workflow содержит jobs с точными именами:
    - [ ] `sdlc-gate` (запускает `scripts/ci/check_secure_sdlc_stage04.sh`)
    - [ ] `sast`
    - [ ] `sca`
    - [ ] `license`
    - [ ] `secrets`
  - [ ] merge в `main` блокируется, если любой job не зелёный (через required checks списка из шага 2)
  - [ ] **Проверка (pass/fail):** workflow существует и реально запускается; branch protection `main` включает required checks ровно из списка шага 2.

- [ ] **13. Сделать:** Реализовать CI workflow релиза Stage 04: SBOM + cosign sign + verify.
  - [ ] существует `.github/workflows/release_stage04.yml`
  - [ ] workflow имеет имя `release-stage04` (точно)
  - [ ] workflow генерирует SBOM (syft, SPDX JSON) как `sbom.spdx.json`
  - [ ] workflow генерирует `checksums.txt` для релизных артефактов
  - [ ] workflow подписывает cosign (keyless OIDC) все артефакты из шага 9
  - [ ] workflow выполняет verify подписи как обязательный шаг
  - [ ] **Проверка (pass/fail):** workflow существует; релизный запуск публикует артефакты + `sbom.spdx.json` + `checksums.txt` + подписи/attestation; verify шаг присутствует и обязателен.

- [ ] **14. Сделать:** Добавить CI gate Stage 04: проверка наличия документов и минимальной валидации их содержания + полная проверка pinning для всех actions, включая actions внутри локальных composite actions.
  - [ ] существует исполняемый скрипт `scripts/ci/check_secure_sdlc_stage04.sh`
  - [ ] скрипт проверяет наличие всех файлов из раздела “Документация (RU)”
  - [ ] скрипт проверяет минимальный контент документов (через grep):
    - [ ] `docs/security/secure_sdlc_policy.md` содержит `clean build` и `reproducible` и требование совпадения хэша артефактов при повторной релизной сборке
    - [ ] `docs/security/branch_tag_policy.md` содержит список required checks из шага 2 (все строки присутствуют)
    - [ ] `docs/security/ci_pinning_policy.md` содержит `commit SHA` и запрет `@v` и запрет удалённых composite actions
    - [ ] `docs/security/sast_policy.md` содержит `semgrep`
    - [ ] `docs/security/sca_policy.md` содержит `osv-scanner` и `licenses`
    - [ ] `docs/security/secrets_policy.md` содержит `gitleaks`
    - [ ] `docs/security/sbom_policy.md` содержит `syft` и `SPDX`
    - [ ] `docs/security/provenance_signing.md` содержит `cosign` и `OIDC` и список артефактов из шага 9
  - [ ] скрипт проверяет pinning всех `uses:` во всех workflow:
    - [ ] во всех `.github/workflows/*.yml` запрещены `uses: ...@v*`, `uses: ...@main`, `uses: ...@master`
    - [ ] во всех `.github/workflows/*.yml` разрешены только:
      - [ ] `uses: owner/repo@<40-hex-sha>`
      - [ ] `uses: ./.github/actions/...` (локальные)
    - [ ] во всех `.github/workflows/*.yml` запрещены `uses: docker://...`
  - [ ] скрипт проверяет pinning внутри всех локальных composite actions:
    - [ ] во всех `.github/actions/**/action.yml` запрещены `uses: ...@v*`, `uses: ...@main`, `uses: ...@master`
    - [ ] во всех `.github/actions/**/action.yml` запрещены `uses: docker://...`
    - [ ] во всех `.github/actions/**/action.yml` удалённые actions допускаются только как `owner/repo@<40-hex-sha>`
  - [ ] **Проверка (pass/fail):** CI зелёный; при нарушении любого запрета pinning/формата `uses:` скрипт падает (exit 1).

## Документация (RU)
- [ ] docs/security/secure_sdlc_policy.md
- [ ] docs/security/branch_tag_policy.md
- [ ] docs/security/ci_pinning_policy.md
- [ ] docs/security/sast_policy.md
- [ ] docs/security/sca_policy.md
- [ ] docs/security/secrets_policy.md
- [ ] docs/security/sbom_policy.md
- [ ] docs/security/provenance_signing.md
- [ ] docs/security/dependency_update_policy.md
- [ ] docs/security/release_hardening.md
- [ ] .github/workflows/security_stage04.yml
- [ ] .github/workflows/release_stage04.yml
- [ ] scripts/ci/check_secure_sdlc_stage04.sh

## Тестирование
- [ ] security CI jobs зелёные на PR в main: `security-stage04 / sdlc-gate`, `sast`, `sca`, `license`, `secrets`
- [ ] release CI jobs зелёные: SBOM + cosign sign + verify

## CI gate
- [ ] `scripts/ci/check_secure_sdlc_stage04.sh` включён в `security-stage04 / sdlc-gate`
- [ ] required checks в branch protection `main` равны списку из шага 2

## DoD
- [ ] Политики Secure SDLC и supply-chain однозначны.
- [ ] Branch protection + required checks реально включены и доказуемы.
- [ ] Verified commits в main обеспечены и проверяемы.
- [ ] CI pinning зафиксирован и проверяется скриптом (включая локальные composite actions).
- [ ] SAST/SCA/license/secrets gates обязательны и блокируют merge при нарушениях.
- [ ] SBOM обязателен для релизов (SPDX JSON) и публикуется как `sbom.spdx.json`.
- [ ] cosign signing (keyless OIDC) обязателен для релизов по перечню артефактов; verify обязателен.

