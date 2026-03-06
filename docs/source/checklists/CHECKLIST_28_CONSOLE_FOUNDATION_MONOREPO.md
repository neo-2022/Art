# CHECKLIST 28 — Console Foundation (Monorepo Apps+Packages)
Файл: CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение monorepo layout, import boundaries, foundation routes Console
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Подготовить production-ready фундамент Tier B Console в одном репозитории `Art`: workspace, package boundaries, базовые поверхности UI, i18n и UI-laws runtime checks.

## Границы
- Включено: `pnpm workspace`, `apps/console-web`, `packages/*`, import boundary checks, foundation tests.
- Исключено: перенос/смешивание кода `browser/` с `apps/console-web`.
- Исключено: реализация функций этапов 29..37.

## Зависимости
- CHECKLIST 00 (MASTER)
- CHECKLIST 07 (repo/CI discipline)
- CHECKLIST 16 (Panel0 baseline)
- FOUNDATION_CONSTITUTION_V0_2.md

## Шаги (строго линейно)
- [x] 1. Сделать: оформить root workspace (`pnpm-workspace.yaml`, root `package.json`, единый `pnpm-lock.yaml`).
  - [x] Проверка (pass/fail): `corepack pnpm install --frozen-lockfile` возвращает код `0`.
  - [x] Артефакт результата: `pnpm-lock.yaml` в репозитории + лог установки CI (`console-workspace-install`).
- [x] 2. Сделать: создать `apps/console-web` и `packages/{ui-laws,i18n,evidence-linking,worker-runtime,local-stores}` с build/test scripts.
  - [x] Проверка (pass/fail): `corepack pnpm run console:build` возвращает код `0`.
  - [x] Артефакт результата: файлы `package.json`, `src/*`, `test/*`, `dist/index.html` (на CI).
- [x] 3. Сделать: зафиксировать import boundaries для monorepo.
  - [x] Запретить импорт `apps/*` из `browser/*`.
  - [x] Запретить прямые импорты `core/`, `agent/`, `browser/` из `apps/console-web`.
  - [x] Запретить прямые относительные импорты в `packages/*` из `apps/console-web` (только через `@art/*`).
  - [x] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает код `0`.
  - [x] Артефакт результата: CI job `workspace-boundary-check`.
- [x] 4. Сделать: реализовать foundation shell с 7 surface routes.
  - [x] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` возвращает код `0`.
  - [x] Артефакт результата: тест-отчёт `apps/console-web/test/console-web.test.mjs`.
- [x] 5. Сделать: enforce i18n foundation (EN default + RU switch) и tooltip laws.
  - [x] Проверка (pass/fail): `corepack pnpm run console:test` и `node --test browser/test/panel0_i18n_laws.test.js` возвращают код `0`.
  - [x] Артефакт результата: логи test jobs `console-test`, `panel0-i18n-law-tests`.
- [x] 6. Сделать: внедрить observability-gap контроль нарушений boundaries.
  - [x] Событие: `observability_gap.console_workspace_boundary_violation`.
  - [x] evidence_min: `module`, `import_path`, `rule`, `trace_id`.
  - [x] action_ref: `docs/runbooks/console_workspace_boundary_violation.md`.
  - [x] Проверка (pass/fail): запись присутствует в `docs/governance/observability_gap_registry.md` и runbook файл существует.
  - [x] Артефакт результата: diff registry + runbook.
- [x] 7. Сделать: зафиксировать метрику архитектурной чистоты `forbidden_import_count=0`.
  - [x] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает `forbidden_import_count=0`.
  - [x] Артефакт результата: отчёт boundary-check с метрикой.
- [x] 8. Сделать: внедрить Lens governance как обязательный нормативный контур этапа 28.
  - [x] Проверка (pass/fail): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` содержит `APPENDIX A — LENS CATALOG`, `A0.0 Classification rule`, `A0.1 Primary / Secondary / Anti-pattern mapping`.
  - [x] Проверка (pass/fail): `test -s docs/foundation/lens_audit_report.md` и `rg -n "^Class: (Primary|Secondary|Anti-pattern)$" docs/foundation/lens_audit_report.md`.
  - [x] Проверка (pass/fail): `rg -n "Evidence-anchored AI|claims без evidence_refs|Code-and-Fix|Timeboxing" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`.
  - [x] Артефакт результата: diff Foundation Appendix + `docs/foundation/lens_audit_report.md` + CI log `stage28-docs-gate`.
- [x] 9. Сделать: добавить отдельный gate `stage28-lens-gate` с проверками Lens governance.
  - [x] Проверка (pass/fail): `.github/workflows/ci.yml` содержит job `stage28-lens-gate`, выполняющий `bash scripts/ci/check_stage28_lens.sh`.
  - [x] Артефакт результата: diff workflow + лог job.
- [x] 10. Сделать: добавить negative smoke для boundary enforcement.
  - [x] Проверка (pass/fail): `bash scripts/tests/workspace_boundary_negative_smoke.sh` возвращает код `0` и подтверждает FAIL boundary-check при искусственном нарушении.
  - [x] Артефакт результата: negative smoke log.
- [x] 11. Сделать: зафиксировать интерфейсную лестницу реализации (`L0->L1->L2->L3`) как обязательный контракт этапов.
  - [x] L0 (stage 28): shell + surfaces skeleton + i18n + tooltip/evidence navigation.
  - [x] L1 (stage 30/31): truth modes + dialog lineage + investigation library baseline.
  - [x] L2 (stage 35): flow mode 2D (inspect/snapshot/replay/diff) + adaptive settings.
  - [x] L3 (post-35): 3D projection как проекция L2 без новых source-of-truth.
  - [x] Проверка (pass/fail): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` содержит разделы `Truth Modes Law`, `Visual Flow Mode Specification`, `Adaptive UX Policy`, `Tiered Testing and CI Law`.
  - [x] Артефакт результата: diff Foundation.
- [x] 12. Сделать: зафиксировать обязательный anti-breakage набор тестов ранних этапов для будущих интерфейсных слоёв.
  - [x] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` содержит проверки surfaces/i18n/tooltips/evidence links и остаётся PASS после изменений stage 30+.
  - [x] Артефакт результата: test log + checklist reference matrix.
- [x] 13. Сделать: заложить foundation settings framework с поиском по настройкам и иерархией групп.
  - [x] Проверка (pass/fail): Console shell содержит settings search + grouped sections (`visual`, `opacity`, `colors`, `audio`) и фильтрацию пунктов по query.
  - [x] Артефакт результата: e2e screenshot + test log.
- [x] 14. Сделать: заложить audio effects framework с legal-safe baseline и пользовательской заменой каждого эффекта.
  - [x] Требование: default эффекты генерируются процедурно (без внешних audio assets).
  - [x] Требование: для каждого эффекта доступны `preview`, `replace`, `clear`.
  - [x] Требование: есть явный legal warning о правах на пользовательский контент.
  - [x] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` PASS и подтверждает наличие audio controls + replace hooks.
  - [x] Артефакт результата: test log + foundation diff.
- [x] 15. Сделать: внедрить runtime e2e suite для audio/settings цепочки.
  - [x] Проверка (pass/fail): `bash scripts/tests/console_audio_settings_e2e.sh` PASS (`search -> preview -> custom-status -> clear`).
  - [x] Артефакт результата: e2e log + обновление CI job `stage28-audio-settings-e2e`.
- [x] 16. Сделать: зафиксировать информационную архитектуру меню настроек всего проекта.
  - [x] Проверка (pass/fail): документ `docs/source/console_settings_architecture_v0_2.md` содержит структуру уровней (`Global/Organization/Project/Environment/User`), категории/подкатегории, policy lock и search model.
  - [x] Артефакт результата: settings architecture doc diff + ссылочный раздел в Foundation.
- [x] 17. Сделать: реализовать Settings Profile Manager (`save/apply/delete/export/import`) для user-scope настроек.
  - [x] Проверка (pass/fail): runtime e2e подтверждает цикл `save -> apply -> export -> import -> delete` с корректными status-сообщениями.
  - [x] Проверка (pass/fail): policy-locked controls помечены и не изменяются через profile apply.
  - [x] Артефакт результата: profile manager e2e log + UI screenshot.

## Документация (RU)
- [x] docs/source/FOUNDATION_CONSTITUTION_V0_2.md
- [x] docs/source/checklists/TRACEABILITY_V0_2.md
- [x] docs/source/checklists/README.md
- [x] docs/source/README.md
- [x] docs/foundation/lens_audit_report.md
- [x] docs/runbooks/console_workspace_boundary_violation.md
- [x] docs/source/risk_register_v0_2.md
- [x] docs/source/console_settings_architecture_v0_2.md

## Тестирование
- [x] unit: пакеты `packages/*` покрыты тестами и запускаются в CI.
- [x] integration: routing foundation shell в `apps/console-web`.
- [x] e2e: Linux headless smoke открытия foundation shell.
- [x] regression: интерфейсная лестница L0 сохраняет обратную совместимость при переходе к L1/L2.
- [x] integration: settings search фильтрует пункты без потери доступности.
- [x] integration: audio replace/preview/clear работает по каждому baseline эффекту.
- [x] e2e: search + audio preview + custom replace status + clear cycle.
- [x] e2e: settings profile manager cycle (`save/apply/export/import/delete`) + policy-lock behavior.
- [x] chaos: отрицательный boundary case (прямой импорт запрещённого пути) падает в CI.
- [x] load: не применяется на этапе 28; переносится в этап 34.
- [x] soak: не применяется на этапе 28; переносится в этап 34.

## CI gate
- [x] `stage28-docs-gate`
- [x] `stage28-risk-gate`
- [x] `console-workspace-install`
- [x] `console-lint`
- [x] `console-test`
- [x] `console-build`
- [x] `workspace-boundary-check`
- [x] `workspace-boundary-negative-smoke`
- [x] `panel0-i18n-law-tests`
- [x] `stage28-lens-gate`
- [x] `stage28-audio-settings-e2e`

## DoD
- [x] Workspace и foundation app/packages воспроизводимо собираются на Linux CI.
- [x] Boundary violations блокируются автоматически.
- [x] Foundation shell содержит 7 поверхностей и проходит test suite.
- [x] Lens Catalog классифицирован (Primary/Secondary/Anti-pattern) и проверяется в stage28 docs gate.
- [x] Lens governance проверяется отдельным CI gate `stage28-lens-gate`.
- [x] Отрицательный boundary smoke подтверждает автоматическую блокировку запрещённых импортов.
- [x] Интерфейсная лестница L0->L3 задокументирована и проверяется как обязательный anti-breakage контракт.
- [x] Settings framework (с поиском) и audio effects framework (replace/preview/clear) реализованы и покрыты тестами.
- [x] Карта меню настроек проекта зафиксирована как расширяемый контракт уровней и policy-lock.
- [x] observability-gap событие этапа 28 задокументировано в registry + runbook.
- [x] Риск R1 из risk register подтверждён метрикой `forbidden_import_count=0`.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_29 запрещён до полного закрытия CHECKLIST_28.
- Артефакты закрытия: CI logs + ссылки на коммит + обновлённый registry.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
