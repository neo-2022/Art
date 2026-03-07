# Реестр полного построчного аудита v0.2

## Source of truth
- `docs/testing/full_line_by_line_audit_program_v0_2.md`

## Слой 1 — Root + GitHub entry layer

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `.github/CODEOWNERS` | REVIEWED | WEAK | Единственный owner `@neo-2022`; governance зависит от одного человека, нет резервной code-owner модели. | 01, 04 |
| `.github/ISSUE_TEMPLATE/bug.yml` | REVIEWED | OK | Структурный входной шаблон; глубину hostile triage оценивать позже в governance слое. | 01 |
| `.github/ISSUE_TEMPLATE/incident.yml` | REVIEWED | OK | Есть отдельный инцидентный шаблон; потребуется дальнейшая сверка с incident lifecycle. | 01 |
| `.github/dependabot.yml` | REVIEWED | OK | Реальный dependency-update baseline появился; weekly + main + 3 ecosystems. | 04 |
| `.github/pull_request_template.md` | REVIEWED | WEAK | Хороший каркас, но не заставляет прикладывать adversarial/negative-path evidence явно. | 01, 38 |
| `.github/workflows/ci.yml` | REVIEWED | WEAK | Очередь уже смягчена, но файл остаётся чрезмерно раздутым; много jobs по-прежнему document/meta oriented. | 07, 38 |
| `.github/workflows/nightly-stage29-replay-determinism.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/nightly_chaos.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/platform_matrix_stage37.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/release_stage04.yml` | REVIEWED | OK | Реальный release pipeline: static artifacts, SBOM, checksums, provenance, cosign sign+verify. | 04, 24 |
| `.github/workflows/required_gates.yml` | REVIEWED | WEAK | Дублирование снижено, но workflow всё ещё повторяет часть security/SDLC смыслов и может расходиться с основным CI-контуром. | 01, 04, 38 |
| `.github/workflows/security_stage04.yml` | REVIEWED | OK | После многократного дебаггинга даёт доказанный эксплуатационный эффект, различает infra failure и findings. | 04 |
| `.github/workflows/stage14-soak-artifacts.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.gitignore` | REVIEWED | OK | Базово адекватен; deeper packaging/runtime leakage проверять позже. | 07 |
| `.gitleaks.toml` | REVIEWED | WEAK | Есть `Temporary allowlist`; даже при осмысленном содержимом сама временная семантика противоречит production-строгости. | 04 |
| `CHANGELOG.md` | REVIEWED | OK | Содержит реальные baseline shifts; позже проверить полноту против фактической истории релизов. | 24 |
| `Cargo.lock` | REVIEWED | OK | Наличие root lockfile соответствует deterministic dependency baseline. | 04 |
| `Cargo.toml` | REVIEWED | OK | Профили `general/certified` уже зафиксированы; deeper certified-runtime check позже в code/platform слоях. | 04, 37 |
| `LICENSE` | REVIEWED | OK | Есть явная лицензия-константа; соответствует private baseline. | 04, 07 |
| `Makefile` | REVIEWED | WEAK | Полезен как dev-entry, но `smoke/security-smoke` ещё не отражают hostile/adversarial философию целиком. | 07, 04 |
| `README.md` | REVIEWED | OK | Сильный product-facing вход, но production candidate claims надо ещё сверить с полным runtime corpus. | 07, 24 |
| `RELEASE_CHECKLIST.md` | REVIEWED | WEAK | Release hygiene есть, но candidate commit и current baseline требуют сверки с реальным HEAD/PR state при каждом цикле. | 24, 37 |
| `SECURITY.md` | REVIEWED | WEAK | Слишком тонкий для зрелого продукта: нет threat-model entry, intake flow, disclosure classes, artifact expectations. | 04, 25 |

## Слой 2 — Канон, foundation, testing и MASTER

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` | REVIEWED | OK | Канон силён и уже включает hostile/adversarial law, Truth Modes, Evidence-First и continuation concepts. Риск не в тексте, а в недоведении кода/тестов до уровня канона. | 00, 28..45 |
| `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md` | REVIEWED | MISMATCH | MASTER уже открыт, но таблица этапов всё ещё хранит старые записи “выполнено” для открытых стадий; это создаёт риск ложного ощущения завершённости. | 00, 38 |
| `docs/source/checklists/TRACEABILITY_V0_2.md` | REVIEWED | WEAK | Хорошо пришивает идеи и stages, но остаётся документом намерения; не все mapping уже материализованы в runtime/test corpus. | 00, 38, 39..45 |
| `docs/source/README.md` | REVIEWED | OK | Корневой source-index адекватный; потребуется later сверка каждого external source link с реальным runtime scope. | 00, 05, 06 |
| `docs/source/Art_v1_spec_final.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/source/risk_register_v0_2.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/lens_audit_report.md` | REVIEWED | WEAK | Хотя стал лучше, всё ещё содержит известные открытые gaps как фон; сам факт наличия unresolved production gaps требует реального reopening downstream stages. | 28, 35, 37, 38 |
| `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md` | REVIEWED | OK | Исторический корпус подробный и полезный; не проблема в содержании, а в runtime-program materialization approved ideas. | 39..45 |
| `docs/foundation/revolutionary_hypotheses.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/frontier_tech_radar.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/testing/production_adversarial_validation_law.md` | REVIEWED | OK | Новый базовый закон сформулирован жёстко и соответствует философии проекта. | 00, all |
| `docs/testing/test_system_audit_v0_2.md` | REVIEWED | WEAK | Уже честно признаёт слабые зоны, но это пока meta-audit; сам проект ещё не приведён к заявленному стандарту. | 00, all |
| `docs/testing/full_line_by_line_audit_program_v0_2.md` | REVIEWED | OK | Корректно фиксирует приказ на буквальный построчный аудит. | 00 |
| `docs/testing/full_line_by_line_audit_registry_v0_2.md` | REVIEWED | OK | Рабочий реестр ретро-аудита, используется как текущий артефакт программы. | 00 |
