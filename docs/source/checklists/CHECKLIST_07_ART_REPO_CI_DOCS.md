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

- [ ] **1. Сделать:** Создать структуру Art repo.
  - [ ] каталог `core/`
  - [ ] каталог `agent/`
  - [ ] каталог `browser/`
  - [ ] каталог `docs/`
  - [ ] каталог `scripts/`
  - [ ] **Проверка (pass/fail):** все каталоги существуют в репозитории Art.

- [ ] **2. Сделать:** В CI включить Rust fmt/clippy/test и Browser lint/test/build.
  - [ ] Rust: `cargo fmt --check`
  - [ ] Rust: `cargo clippy` (fail при ошибках)
  - [ ] Rust: `cargo test`
  - [ ] Browser: lint
  - [ ] Browser: test
  - [ ] Browser: build
  - [ ] **Проверка (pass/fail):** существуют workflow-файлы CI, jobs запускаются на PR в main и зелёные.

- [ ] **3. Сделать:** В CI включить `gitleaks` (secrets scan) как blocking job.
  - [ ] job запускается на PR в main и на push в main
  - [ ] job блокирует merge при падении
  - [ ] **Проверка (pass/fail):** job существует, и при искусственном добавлении тестового секрета (в отдельной ветке) job падает.

- [ ] **4. Сделать:** В CI включить license checks: `cargo-deny` (licenses) и JS license checker (инструмент фиксирован).
  - [ ] Rust license job: `cargo deny check licenses`
  - [ ] JS license job: выбран и зафиксирован единый инструмент: `license-checker` (npm пакет)
  - [ ] JS license job выполняет команду: `npx license-checker --production --summary`
  - [ ] оба job’а blocking (падение блокирует merge)
  - [ ] **Проверка (pass/fail):** jobs существуют и запускаются на PR в main.

- [ ] **5. Сделать:** В README закрепить контракты как источник правды (декларация Stage 07) и указать, что сами файлы контрактов добавляются на Stage 08.
  - [ ] README содержит раздел `Contracts`
  - [ ] в `Contracts` перечислены будущие пути контрактов:
    - [ ] OpenAPI (путь указан)
    - [ ] JSON Schema (путь указан)
  - [ ] явно указано: файлы контрактов (OpenAPI/JSON Schema) добавляются на Stage 08
  - [ ] явно указано: CI Stage 07 проверяет только наличие декларации `Contracts` в README (без требования наличия файлов контрактов)
  - [ ] **Проверка (pass/fail):** README содержит раздел `Contracts` со всеми пунктами выше.

- [ ] **6. Сделать:** Создать RU dev docs: как собрать/запустить/прогнать тесты.
  - [ ] `docs/development/getting_started.md` существует
  - [ ] содержит команды build/run/test для Rust
  - [ ] содержит команды lint/test/build для Browser
  - [ ] **Проверка (pass/fail):** документ существует и содержит команды, которые реально запускаются.

- [ ] **7. Сделать:** Описать dev env (RU): версии toolchain, переменные окружения, настройка локальных зависимостей.
  - [ ] `docs/development/dev_env.md` существует
  - [ ] содержит версии Rust toolchain / Node
  - [ ] содержит список env vars (название + назначение)
  - [ ] **Проверка (pass/fail):** документ существует и заполнен.

- [ ] **8. Сделать:** Добавить CI gate Stage 07 для минимальной валидации содержимого (не только существование файлов).
  - [ ] существует `scripts/ci/check_art_repo_stage07.sh`
  - [ ] скрипт исполняемый
  - [ ] скрипт запускается в CI как отдельный blocking job
  - [ ] проверки содержимого:
    - [ ] README содержит `Contracts`
    - [ ] в `Contracts` присутствуют строки `Stage 08` и упоминание OpenAPI/JSON Schema
    - [ ] `docs/development/getting_started.md` содержит строки `cargo` и `node` (или `npm`/`pnpm`) команды
    - [ ] `docs/development/dev_env.md` содержит строки `Rust` и `Node` (или версии toolchain)
    - [ ] `docs/development/getting_started.md` содержит команду JS license checker: `license-checker`
  - [ ] **Проверка (pass/fail):** CI зелёный; при удалении раздела `Contracts` или пустых dev docs скрипт падает (exit 1).

## Документация (RU)
- [ ] README.md
- [ ] docs/development/getting_started.md
- [ ] docs/development/dev_env.md
- [ ] scripts/ci/check_art_repo_stage07.sh

## Тестирование
- [ ] smoke: единая команда (или набор команд), который прогоняет lint/test/build для Rust и Browser (указана в docs)
- [ ] security smoke: локальный запуск `gitleaks` (команда указана в docs)

## CI gate
- [ ] Rust fmt/clippy/test зелёные
- [ ] Browser lint/test/build зелёные
- [ ] gitleaks зелёный
- [ ] license checks зелёные (cargo-deny + license-checker)
- [ ] `scripts/ci/check_art_repo_stage07.sh` зелёный

## DoD
- [ ] Структура репозитория создана.
- [ ] CI jobs существуют, запускаются на PR в main и blocking.
- [ ] RU dev docs существуют и содержат реальные команды.
- [ ] README фиксирует декларацию Contracts и помечает, что файлы контрактов добавляются на Stage 08; CI Stage 07 проверяет только декларацию.
- [ ] CI gate Stage 07 проходит.

