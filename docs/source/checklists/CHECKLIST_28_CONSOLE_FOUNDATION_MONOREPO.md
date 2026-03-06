# CHECKLIST 28 — Console Foundation (Monorepo Apps+Packages)
Файл: CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение monorepo layout, import boundaries, foundation routes Console

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
- [ ] 1. Сделать: оформить root workspace (`pnpm-workspace.yaml`, root `package.json`, единый `pnpm-lock.yaml`).
  - [ ] Проверка (pass/fail): `corepack pnpm install --frozen-lockfile` возвращает код `0`.
  - [ ] Артефакт результата: `pnpm-lock.yaml` в репозитории + лог установки CI (`console-workspace-install`).
- [ ] 2. Сделать: создать `apps/console-web` и `packages/{ui-laws,i18n,evidence-linking,worker-runtime,local-stores}` с build/test scripts.
  - [ ] Проверка (pass/fail): `corepack pnpm run console:build` возвращает код `0`.
  - [ ] Артефакт результата: файлы `package.json`, `src/*`, `test/*`, `dist/index.html` (на CI).
- [ ] 3. Сделать: зафиксировать import boundaries для monorepo.
  - [ ] Запретить импорт `apps/*` из `browser/*`.
  - [ ] Запретить прямые импорты `core/`, `agent/`, `browser/` из `apps/console-web`.
  - [ ] Запретить прямые относительные импорты в `packages/*` из `apps/console-web` (только через `@art/*`).
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает код `0`.
  - [ ] Артефакт результата: CI job `workspace-boundary-check`.
- [ ] 4. Сделать: реализовать foundation shell с 7 surface routes.
  - [ ] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` возвращает код `0`.
  - [ ] Артефакт результата: тест-отчёт `apps/console-web/test/console-web.test.mjs`.
- [ ] 5. Сделать: enforce i18n foundation (EN default + RU switch) и tooltip laws.
  - [ ] Проверка (pass/fail): `corepack pnpm run console:test` и `node --test browser/test/panel0_i18n_laws.test.js` возвращают код `0`.
  - [ ] Артефакт результата: логи test jobs `console-test`, `panel0-i18n-law-tests`.
- [ ] 6. Сделать: внедрить observability-gap контроль нарушений boundaries.
  - [ ] Событие: `observability_gap.console_workspace_boundary_violation`.
  - [ ] evidence_min: `module`, `import_path`, `rule`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/console_workspace_boundary_violation.md`.
  - [ ] Проверка (pass/fail): запись присутствует в `docs/governance/observability_gap_registry.md` и runbook файл существует.
  - [ ] Артефакт результата: diff registry + runbook.
- [ ] 7. Сделать: зафиксировать метрику архитектурной чистоты `forbidden_import_count=0`.
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает `forbidden_import_count=0`.
  - [ ] Артефакт результата: отчёт boundary-check с метрикой.
- [ ] 8. Сделать: внедрить Lens governance как обязательный нормативный контур этапа 28.
  - [ ] Проверка (pass/fail): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` содержит `APPENDIX A — LENS CATALOG`, `A0.0 Classification rule`, `A0.1 Primary / Secondary / Anti-pattern mapping`.
  - [ ] Проверка (pass/fail): `test -s docs/foundation/lens_audit_report.md` и `rg -n "^Class: (Primary|Secondary|Anti-pattern)$" docs/foundation/lens_audit_report.md`.
  - [ ] Проверка (pass/fail): `rg -n "Evidence-anchored AI|claims без evidence_refs|Code-and-Fix|Timeboxing" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`.
  - [ ] Артефакт результата: diff Foundation Appendix + `docs/foundation/lens_audit_report.md` + CI log `stage28-docs-gate`.
- [ ] 9. Сделать: добавить отдельный gate `stage28-lens-gate` с проверками Lens governance.
  - [ ] Проверка (pass/fail): `.github/workflows/ci.yml` содержит job `stage28-lens-gate`, выполняющий `bash scripts/ci/check_stage28_lens.sh`.
  - [ ] Артефакт результата: diff workflow + лог job.
- [ ] 10. Сделать: добавить negative smoke для boundary enforcement.
  - [ ] Проверка (pass/fail): `bash scripts/tests/workspace_boundary_negative_smoke.sh` возвращает код `0` и подтверждает FAIL boundary-check при искусственном нарушении.
  - [ ] Артефакт результата: negative smoke log.

## Документация (RU)
- [ ] docs/source/FOUNDATION_CONSTITUTION_V0_2.md
- [ ] docs/source/checklists/TRACEABILITY_V0_2.md
- [ ] docs/source/checklists/README.md
- [ ] docs/source/README.md
- [ ] docs/foundation/lens_audit_report.md
- [ ] docs/runbooks/console_workspace_boundary_violation.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] unit: пакеты `packages/*` покрыты тестами и запускаются в CI.
- [ ] integration: routing foundation shell в `apps/console-web`.
- [ ] e2e: Linux headless smoke открытия foundation shell.
- [ ] chaos: отрицательный boundary case (прямой импорт запрещённого пути) падает в CI.
- [ ] load: не применяется на этапе 28; переносится в этап 34.
- [ ] soak: не применяется на этапе 28; переносится в этап 34.

## CI gate
- [ ] `stage28-docs-gate`
- [ ] `stage28-risk-gate`
- [ ] `console-workspace-install`
- [ ] `console-lint`
- [ ] `console-test`
- [ ] `console-build`
- [ ] `workspace-boundary-check`
- [ ] `workspace-boundary-negative-smoke`
- [ ] `panel0-i18n-law-tests`
- [ ] `stage28-lens-gate`

## DoD
- [ ] Workspace и foundation app/packages воспроизводимо собираются на Linux CI.
- [ ] Boundary violations блокируются автоматически.
- [ ] Foundation shell содержит 7 поверхностей и проходит test suite.
- [ ] Lens Catalog классифицирован (Primary/Secondary/Anti-pattern) и проверяется в stage28 docs gate.
- [ ] Lens governance проверяется отдельным CI gate `stage28-lens-gate`.
- [ ] Отрицательный boundary smoke подтверждает автоматическую блокировку запрещённых импортов.
- [ ] observability-gap событие этапа 28 задокументировано в registry + runbook.
- [ ] Риск R1 из risk register подтверждён метрикой `forbidden_import_count=0`.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_29 запрещён до полного закрытия CHECKLIST_28.
- Артефакты закрытия: CI logs + ссылки на коммит + обновлённый registry.
