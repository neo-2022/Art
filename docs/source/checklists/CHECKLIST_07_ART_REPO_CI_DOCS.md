A) Полный запрет опциональности:
# CHECKLIST 07 — Art repo WP0 (структура, CI, RU dev docs)
Файл: CHECKLIST_07_ART_REPO_CI_DOCS.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение CI; смена security tools; изменение структуры repo

## Цель
Создать репозиторий Art и базовый CI: структура, fmt/lint/test/build, secrets scan, license checks, RU dev docs, и декларация контрактов (OpenAPI/Schema) как источника правды.

## Границы
Инфраструктура репо и CI для Art (не реализация функционала Art).

## Зависимости
- CHECKLIST 01 — Governance/SRE
- CHECKLIST 02 — Privacy baseline (global)
- CHECKLIST 03 — Regional profiles
- CHECKLIST 04 — Secure SDLC + Supply-chain

## Шаги (строго линейно)

- [x] **1. Сделать:** Создать структуру Art repo.
  - [x] каталог `core/`
  - [x] каталог `agent/`
  - [x] каталог `browser/`
  - [x] каталог `docs/`
  - [x] каталог `scripts/`
  - [x] **Проверка (pass/fail):** все каталоги существуют в репозитории Art.

- [x] **2. Сделать:** В CI включить Rust fmt/clippy/test и Browser lint/test/build.
  - [x] Rust: `cargo fmt --check`
  - [x] Rust: `cargo clippy` (fail при ошибках)
  - [x] Rust: `cargo test`
  - [x] Browser: lint
  - [x] Browser: test
  - [x] Browser: build
  - [x] **Проверка (pass/fail):** workflow `.github/workflows/ci.yml` содержит jobs `stage07-rust` и `stage07-browser`; локально `make smoke` = pass.

- [x] **3. Сделать:** В CI включить `gitleaks` (secrets scan) как blocking job.
  - [x] job запускается на PR в main и на push в main
  - [x] job блокирует merge при падении
  - [x] **Проверка (pass/fail):** job `gitleaks` добавлен в `.github/workflows/ci.yml`; локально `gitleaks detect --no-git --source .` с тестовым `ghp_...` даёт `exit=1`.

- [x] **4. Сделать:** В CI включить license checks: `cargo-deny` (licenses) и JS license checker (инструмент фиксирован).
  - [x] Rust license job: `cargo deny check licenses`
  - [x] JS license job: выбран и зафиксирован единый инструмент: `license-checker` (npm пакет)
  - [x] JS license job выполняет команду: `npx license-checker --production --summary`
  - [x] оба job’а blocking (падение блокирует merge)
  - [x] **Проверка (pass/fail):** job `stage07-license-checks` добавлен в `.github/workflows/ci.yml`; локально `cargo deny check licenses` = `licenses ok`, `npx license-checker --production --summary` = `ok`.

- [x] **5. Сделать:** В README закрепить контракты как источник правды (декларация Stage 07) и указать, что сами файлы контрактов добавляются на Stage 08.
  - [x] README содержит раздел `Contracts`
  - [x] в `Contracts` перечислены будущие пути контрактов:
    - [x] OpenAPI (путь указан)
    - [x] JSON Schema (путь указан)
  - [x] явно указано: файлы контрактов (OpenAPI/JSON Schema) добавляются на Stage 08
  - [x] явно указано: CI Stage 07 проверяет только наличие декларации `Contracts` в README (без требования наличия файлов контрактов)
  - [x] **Проверка (pass/fail):** `README.md` содержит раздел `Contracts` со всеми пунктами выше.

- [x] **6. Сделать:** Создать RU dev docs: как собрать/запустить/прогнать тесты.
  - [x] `docs/development/getting_started.md` существует
  - [x] содержит команды build/run/test для Rust
  - [x] содержит команды lint/test/build для Browser
  - [x] **Проверка (pass/fail):** документ существует и содержит команды, которые реально запускаются (`make smoke` = pass).

- [x] **7. Сделать:** Описать dev env (RU): версии toolchain, переменные окружения, настройка локальных зависимостей.
  - [x] `docs/development/dev_env.md` существует
  - [x] содержит версии Rust toolchain / Node
  - [x] содержит список env vars (название + назначение)
  - [x] **Проверка (pass/fail):** документ существует и заполнен.

- [x] **8. Сделать:** Добавить CI gate Stage 07 для минимальной валидации содержимого (не только существование файлов).
  - [x] существует `scripts/ci/check_art_repo_stage07.sh`
  - [x] скрипт исполняемый
  - [x] скрипт запускается в CI как отдельный blocking job
  - [x] проверки содержимого:
    - [x] README содержит `Contracts`
    - [x] в `Contracts` присутствуют строки `Stage 08` и упоминание OpenAPI/JSON Schema
    - [x] `docs/development/getting_started.md` содержит строки `cargo` и `node` (или `npm`/`pnpm`) команды
    - [x] `docs/development/dev_env.md` содержит строки `Rust` и `Node` (или версии toolchain)
    - [x] `docs/development/getting_started.md` содержит команду JS license checker: `license-checker`
  - [x] **Проверка (pass/fail):** `bash scripts/ci/check_art_repo_stage07.sh` = pass.

## Документация (RU)
- [x] README.md
- [x] docs/development/getting_started.md
- [x] docs/development/dev_env.md
- [x] scripts/ci/check_art_repo_stage07.sh

## Тестирование
- [x] smoke: единая команда `make smoke`, которая прогоняет lint/test/build для Rust и Browser (указана в docs)
- [x] security smoke: локальный запуск `gitleaks` (команда указана в docs); `gitleaks detect --source . --redact` = pass, `--no-git` с тестовым `ghp_...` = fail.

## CI gate
- [x] Rust fmt/clippy/test зелёные
- [x] Browser lint/test/build зелёные
- [x] gitleaks зелёный
- [x] license checks зелёные (cargo-deny + license-checker)
- [x] `scripts/ci/check_art_repo_stage07.sh` зелёный

## DoD
- [x] Структура репозитория создана.
- [x] CI jobs существуют, запускаются на PR в main и blocking.
- [x] RU dev docs существуют и содержат реальные команды.
- [x] README фиксирует декларацию Contracts и помечает, что файлы контрактов добавляются на Stage 08; CI Stage 07 проверяет только декларацию.
- [x] CI gate Stage 07 проходит.
