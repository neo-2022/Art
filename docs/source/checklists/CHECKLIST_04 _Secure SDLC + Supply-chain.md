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

- [x] **1. Сделать:** Описать политику Secure SDLC (общая) и требования “clean build / reproducible build”.
  - [x] сборка выполняется в чистом окружении CI (без использования локальных артефактов)
  - [x] зависимости фиксируются lock-файлами и/или pinned версиями
  - [x] сборка детерминирована: одинаковый вход → одинаковый результат
  - [x] для релизных сборок: хэш каждого релизного артефакта совпадает при повторных сборках из одного и того же коммита (rebuild from same commit → identical artifact hash)
  - [x] запрещено использовать “latest” для инструментов сборки/линтеров/сканеров в CI
  - [x] **Проверка (pass/fail):** существует `docs/security/secure_sdlc_policy.md`, содержит все пункты выше явно, включая требование совпадения хэша артефактов при повторной релизной сборке из того же коммита.

- [x] **2. Сделать:** Описать branch policy + tag/release policy (enforce через branch protection) без двусмысленностей, включая точные required status checks.
  - [x] прямые коммиты в `main` запрещены
  - [x] изменения попадают в `main` только через PR
  - [x] required status checks в `main` включены
  - [x] required reviews включены (минимум 1)
  - [x] CODEOWNERS включён и влияет на required reviews
  - [x] force-push в `main` запрещён
  - [x] теги релизов защищены (запрет переписывания релизных тегов)
  - [x] required status checks для `main` заданы точным списком имён (без “и т.п.”):
    - [x] `sdlc-gate`
    - [x] `sast`
    - [x] `sca`
    - [x] `license`
    - [x] `secrets`
  - [x] **Проверка (pass/fail):** существует `docs/security/branch_tag_policy.md`, содержит все пункты выше явно, включая полный список required status checks с точными именами.

- [x] **3. Сделать:** Зафиксировать требование подписанных коммитов в `main` и правило проверки.
  - [x] каждый коммит в `main` имеет “Verified” подпись в UI GitHub (единый критерий)
  - [x] merge в `main` блокируется, если коммит(ы) не “Verified”
  - [x] **Проверка (pass/fail):** `docs/security/branch_tag_policy.md` содержит требование “Verified commits only in main” и требование блокировки merge при нарушении.

- [x] **4. Сделать:** Зафиксировать политику pinning supply-chain в CI (GitHub Actions и внешние инструменты), включая запрет удалённых composite actions.
  - [x] GitHub Actions в workflow закреплены на commit SHA (запрещены `@vX`, `@main`, `@master`)
  - [x] удалённые composite actions запрещены
  - [x] разрешены только локальные composite actions из репозитория (`uses: ./.github/actions/...`)
  - [x] внешние CLI инструменты (semgrep/gitleaks/osv/syft/cosign и т.п.) закреплены по версии
  - [x] разрешённые источники загрузки инструментов перечислены (GitHub Releases/официальные registries)
  - [x] **Проверка (pass/fail):** существует `docs/security/ci_pinning_policy.md`, содержит все пункты выше явно.

- [x] **5. Сделать:** Описать SAST policy и обязательные правила (PR gate + baseline).
  - [x] выбран единый SAST инструмент: `semgrep`
  - [x] правила semgrep закреплены по версии (ruleset pinned)
  - [x] SAST выполняется на каждом PR в `main`
  - [x] политика фейла: найденные issues уровня “error” блокируют merge
  - [x] **Проверка (pass/fail):** существует `docs/security/sast_policy.md`, содержит все пункты выше явно.

- [x] **6. Сделать:** Описать SCA + license checks policy (vuln + лицензии) и PR gate.
  - [x] SCA выполняется на каждом PR в `main`
  - [x] выбран единый источник уязвимостей: OSV
  - [x] выбран инструмент SCA: `osv-scanner`
  - [x] license checks выполняются на каждом PR в `main`
  - [x] политика фейла: запрещённые лицензии блокируют merge
  - [x] **Проверка (pass/fail):** существует `docs/security/sca_policy.md`, содержит:
    - [x] инструмент `osv-scanner`
    - [x] правила фейла по severity (критерии перечислены)
    - [x] список запрещённых лицензий (явный список)
    - [x] правило блокировки merge при нарушении

- [x] **7. Сделать:** Описать secrets scanning policy и PR gate.
  - [x] выбран инструмент: `gitleaks`
  - [x] secrets scan выполняется на каждом PR в `main` и на push в `main`
  - [x] политика фейла: любые найденные secrets блокируют merge
  - [x] исключения допускаются только через allowlist-файл, который перечисляет конкретные пути/паттерны и проходит code review
  - [x] **Проверка (pass/fail):** существует `docs/security/secrets_policy.md`, содержит все пункты выше явно.

- [x] **8. Сделать:** Описать SBOM policy: генерация, формат, хранение, связка с релизом.
  - [x] выбран инструмент: `syft`
  - [x] формат SBOM: SPDX JSON
  - [x] SBOM генерируется для каждого релиза
  - [x] SBOM прикладывается к релизным артефактам и публикуется как релизный asset
  - [x] **Проверка (pass/fail):** существует `docs/security/sbom_policy.md`, содержит все пункты выше явно.

- [x] **9. Сделать:** Описать provenance/signing policy (sigstore/cosign) для релизных артефактов и правило verify, включая точный перечень подписываемых артефактов.
  - [x] выбран инструмент подписи: `cosign` (sigstore)
  - [x] режим подписи: keyless через OIDC GitHub Actions
  - [x] подписываются все релизные артефакты из фиксированного перечня:
    - [x] `agent/dist/*`
    - [x] `ui/dist/*`
    - [x] `sbom.spdx.json`
    - [x] `checksums.txt`
  - [x] verify выполняется в CI как обязательный gate для релизов
  - [x] подписи/attestation публикуются вместе с релизом
  - [x] **Проверка (pass/fail):** существует `docs/security/provenance_signing.md`, содержит все пункты выше явно, включая перечень артефактов.

- [x] **10. Сделать:** Зафиксировать policy для dependency updates (автообновления) и правило “безопасного обновления”.
  - [x] включён механизм PR-обновлений зависимостей (Dependabot)
  - [x] PR обновления зависимостей проходит те же security gates (SAST/SCA/license/secrets)
  - [x] запрещены апдейты зависимостей без PR
  - [x] **Проверка (pass/fail):** существует `docs/security/dependency_update_policy.md`, содержит:
    - [x] выбранный механизм (Dependabot)
    - [x] правило PR-only
    - [x] правило прохождения security gates

- [x] **11. Сделать:** Зафиксировать release hardening: кто может делать релиз, откуда берутся артефакты, запрет локальных релизов.
  - [x] релиз создаётся только из CI workflow (локальные релизы запрещены)
  - [x] источник релиза: тег, созданный через PR/CI процедуру
  - [x] релизный workflow требует зелёных security jobs перед публикацией
  - [x] **Проверка (pass/fail):** существует `docs/security/release_hardening.md`, содержит все пункты выше явно.

- [x] **12. Сделать:** Реализовать CI workflow Stage 04: security jobs и gates.
  - [x] существует `.github/workflows/security_stage04.yml`
  - [x] workflow имеет имя `security-stage04` (точно)
  - [x] workflow запускается на PR в `main` и на push в `main`
  - [x] workflow содержит jobs с точными именами:
    - [x] `sdlc-gate` (запускает `scripts/ci/check_secure_sdlc_stage04.sh`)
    - [x] `sast`
    - [x] `sca`
    - [x] `license`
    - [x] `secrets`
  - [x] merge в `main` блокируется, если любой job не зелёный (через required checks списка из шага 2)
  - [x] **Проверка (pass/fail):** workflow существует и реально запускается; branch protection `main` включает required checks ровно из списка шага 2.

- [x] **13. Сделать:** Реализовать CI workflow релиза Stage 04: SBOM + cosign sign + verify.
  - [x] существует `.github/workflows/release_stage04.yml`
  - [x] workflow имеет имя `release-stage04` (точно)
  - [x] workflow генерирует SBOM (syft, SPDX JSON) как `sbom.spdx.json`
  - [x] workflow генерирует `checksums.txt` для релизных артефактов
  - [x] workflow подписывает cosign (keyless OIDC) все артефакты из шага 9
  - [x] workflow выполняет verify подписи как обязательный шаг
  - [x] **Проверка (pass/fail):** workflow существует; релизный запуск публикует артефакты + `sbom.spdx.json` + `checksums.txt` + подписи/attestation; verify шаг присутствует и обязателен (run `22705930171`, tag `v0.0.0-stage04-20260305094652`).

- [x] **14. Сделать:** Добавить CI gate Stage 04: проверка наличия документов и минимальной валидации их содержания + полная проверка pinning для всех actions, включая actions внутри локальных composite actions.
  - [x] существует исполняемый скрипт `scripts/ci/check_secure_sdlc_stage04.sh`
  - [x] скрипт проверяет наличие всех файлов из раздела “Документация (RU)”
  - [x] скрипт проверяет минимальный контент документов (через grep):
    - [x] `docs/security/secure_sdlc_policy.md` содержит `clean build` и `reproducible` и требование совпадения хэша артефактов при повторной релизной сборке
    - [x] `docs/security/branch_tag_policy.md` содержит список required checks из шага 2 (все строки присутствуют)
    - [x] `docs/security/ci_pinning_policy.md` содержит `commit SHA` и запрет `@v` и запрет удалённых composite actions
    - [x] `docs/security/sast_policy.md` содержит `semgrep`
    - [x] `docs/security/sca_policy.md` содержит `osv-scanner` и `licenses`
    - [x] `docs/security/secrets_policy.md` содержит `gitleaks`
    - [x] `docs/security/sbom_policy.md` содержит `syft` и `SPDX`
    - [x] `docs/security/provenance_signing.md` содержит `cosign` и `OIDC` и список артефактов из шага 9
  - [x] скрипт проверяет pinning всех `uses:` во всех workflow:
    - [x] во всех `.github/workflows/*.yml` запрещены `uses: ...@v*`, `uses: ...@main`, `uses: ...@master`
    - [x] во всех `.github/workflows/*.yml` разрешены только:
      - [x] `uses: owner/repo@<40-hex-sha>`
      - [x] `uses: ./.github/actions/...` (локальные)
    - [x] во всех `.github/workflows/*.yml` запрещены `uses: docker://...`
  - [x] скрипт проверяет pinning внутри всех локальных composite actions:
    - [x] во всех `.github/actions/**/action.yml` запрещены `uses: ...@v*`, `uses: ...@main`, `uses: ...@master`
    - [x] во всех `.github/actions/**/action.yml` запрещены `uses: docker://...`
    - [x] во всех `.github/actions/**/action.yml` удалённые actions допускаются только как `owner/repo@<40-hex-sha>`
  - [x] **Проверка (pass/fail):** CI зелёный; при нарушении любого запрета pinning/формата `uses:` скрипт падает (exit 1) — pass: `bash scripts/ci/check_secure_sdlc_stage04.sh`; fail check: временный `.github/workflows/_tmp_bad_pin.yml` с `uses: actions/checkout@v4` дал `RC=1`.

## Документация (RU)
- [x] docs/security/secure_sdlc_policy.md
- [x] docs/security/branch_tag_policy.md
- [x] docs/security/ci_pinning_policy.md
- [x] docs/security/sast_policy.md
- [x] docs/security/sca_policy.md
- [x] docs/security/secrets_policy.md
- [x] docs/security/sbom_policy.md
- [x] docs/security/provenance_signing.md
- [x] docs/security/dependency_update_policy.md
- [x] docs/security/release_hardening.md
- [x] .github/workflows/security_stage04.yml
- [x] .github/workflows/release_stage04.yml
- [x] scripts/ci/check_secure_sdlc_stage04.sh

## Тестирование
- [x] security CI jobs зелёные на PR в main: `sdlc-gate`, `sast`, `sca`, `license`, `secrets` (run `22705479817`, success)
- [x] release CI jobs зелёные: SBOM + cosign sign + verify (run `22705930171`, success)

## CI gate
- [x] `scripts/ci/check_secure_sdlc_stage04.sh` включён в `security-stage04 / sdlc-gate`
- [x] required checks в branch protection `main` равны списку из шага 2

## DoD
- [x] Политики Secure SDLC и supply-chain однозначны.
- [x] Branch protection + required checks реально включены и доказуемы.
- [x] Verified commits в main обеспечены и проверяемы.
- [x] CI pinning зафиксирован и проверяется скриптом (включая локальные composite actions).
- [x] SAST/SCA/license/secrets gates обязательны и блокируют merge при нарушениях.
- [x] SBOM обязателен для релизов (SPDX JSON) и публикуется как `sbom.spdx.json`.
- [x] cosign signing (keyless OIDC) обязателен для релизов по перечню артефактов; verify обязателен.
